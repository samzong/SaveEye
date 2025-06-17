//
//  AppState.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Combine
import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var showConfig = true
    @Published var isRunning = false
    @Published var showEyeCare = false

    // 计时器和监控器实例
    private var eyeCareTimer: EyeCareTimer?
    private var activityMonitor: ActivityMonitor?
    private var exitStateMachine: ExitStateMachine?
    private var escapeKeyMonitor: EscapeKeyMonitor?
    var settings: Settings?
    private var eyeCareWindows: [NSWindow] = []
    private var cancellables = Set<AnyCancellable>()

    // 初始化方法
    func initialize(settings: Settings, activityMonitor: ActivityMonitor) {
        self.settings = settings
        self.activityMonitor = activityMonitor
        eyeCareTimer = EyeCareTimer(settings: settings, activityMonitor: activityMonitor)
        exitStateMachine = ExitStateMachine(settings: settings)
        escapeKeyMonitor = EscapeKeyMonitor()

        // 监听计时器状态
        eyeCareTimer?.$shouldShowEyeCare
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.triggerEyeCare()
                }
            }
            .store(in: &cancellables)

        // 监听退出状态机通知
        setupExitStateMachineNotifications()

        // 恢复运行状态
        restoreRunningState()

        // 确保护眼窗口在后台创建
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.ensureEyeCareWindowExists()
        }
    }

    // 恢复运行状态
    private func restoreRunningState() {
        guard let settings = settings else { return }

        if settings.isProtectionRunning {
            isRunning = true
            activityMonitor?.startMonitoring()

            // 恢复计时器（考虑已经过去的时间）
            if let lastStartTime = settings.lastWorkStartTime {
                let elapsed = Date().timeIntervalSince(lastStartTime)
                let intervalSeconds = TimeInterval(settings.breakIntervalMinutes * 60)

                if elapsed < intervalSeconds {
                    eyeCareTimer?.resumeFromElapsed(elapsed)
                } else {
                    eyeCareTimer?.reset()
                    settings.lastWorkStartTime = Date()
                    eyeCareTimer?.start()
                }
            } else {
                eyeCareTimer?.start()
                settings.lastWorkStartTime = Date()
            }
        }
    }

    // 应用状态控制
    func startProtection() {
        isRunning = true

        // 保存运行状态
        settings?.isProtectionRunning = true
        settings?.lastWorkStartTime = Date()

        // 启动活动监控和计时器
        activityMonitor?.startMonitoring()
        eyeCareTimer?.start()
    }

    func stopProtection() {
        isRunning = false
        showEyeCare = false

        settings?.isProtectionRunning = false
        settings?.lastWorkStartTime = nil

        // 停止活动监控和计时器
        activityMonitor?.stopMonitoring()
        eyeCareTimer?.stop()

        eyeCareTimer?.reset()
    }

    func hideConfig() {
        showConfig = false
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "config" }) {
                window.close()
            }
        }
    }

    func showConfigWindow() {
        showConfig = true
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // 护眼窗口控制
    func triggerEyeCare() {
        showEyeCare = true
        // 启动ESC键监听
        escapeKeyMonitor?.startMonitoring()

        // 进入真正的全屏模式
        DispatchQueue.main.async {
            self.enterFullScreenEyeCareMode()
        }
    }

    func dismissEyeCare() {
        showEyeCare = false
        // 停止ESC键监听
        escapeKeyMonitor?.stopMonitoring()

        // 退出全屏模式
        exitFullScreenEyeCareMode()

        // 护眼结束后重置计时器
        eyeCareTimer?.reset()
        // 重置退出状态机
        exitStateMachine?.forceReset()
    }

    // 进入真正的全屏护眼模式
    private func enterFullScreenEyeCareMode() {
        setAppPresentationOptions([.hideDock, .hideMenuBar, .disableAppleMenu, .disableProcessSwitching, .disableHideApplication])
        createFullScreenEyeCareWindows()
    }

    // 退出全屏护眼模式
    private func exitFullScreenEyeCareMode() {
        closeAllEyeCareWindows()
        setAppPresentationOptions([])
    }

    private func createFullScreenEyeCareWindows() {
        let screens = NSScreen.screens

        closeAllEyeCareWindows()

        for (_, screen) in screens.enumerated() {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            // 设置窗口属性 - 真正的全屏覆盖
            window.level = NSWindow.Level.screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenDisallowsTiling]
            window.isReleasedWhenClosed = false
            window.backgroundColor = NSColor.black
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = false

            let fullFrame = screen.frame
            window.setFrame(fullFrame, display: true)

            let contentView = EyeCareWindow()
                .environmentObject(self)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            window.contentView = NSHostingView(rootView: contentView)

            window.setFrameOrigin(screen.frame.origin)
            window.makeKeyAndOrderFront(nil)

            eyeCareWindows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)

        if let mainWindow = eyeCareWindows.first {
            mainWindow.level = NSWindow.Level.screenSaver
            mainWindow.orderFrontRegardless()
        }
    }

    // 延迟休息
    func delayBreak(minutes: Int) {
        eyeCareTimer?.delayBreak(minutes: minutes)
        showEyeCare = false
    }

    // 获取计时器状态信息
    var timerStatus: String {
        return eyeCareTimer?.statusDescription ?? "未初始化"
    }

    var timeRemaining: String {
        return eyeCareTimer?.formattedTimeRemaining ?? "00:00"
    }

    // 处理ESC按键
    func handleEscapeKey() {
        exitStateMachine?.handleEscapePress()
    }

    // 获取退出状态机状态
    var exitStateMessage: String {
        return exitStateMachine?.showMessage ?? ""
    }

    var shouldShowExitMessage: Bool {
        return exitStateMachine?.shouldShowMessage ?? false
    }

    // 设置退出状态机通知
    private func setupExitStateMachineNotifications() {
        NotificationCenter.default.publisher(for: .exitStateMachineDidTriggerExit)
            .sink { [weak self] _ in
                self?.handleExitTriggered()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .exitStateMachineDidTriggerDelay)
            .sink { [weak self] _ in
                self?.handleDelayTriggered()
            }
            .store(in: &cancellables)

        // 监听ESC键按下
        NotificationCenter.default.publisher(for: .escapeKeyPressed)
            .sink { [weak self] _ in
                self?.handleEscapeKey()
            }
            .store(in: &cancellables)
    }

    // 处理退出触发
    private func handleExitTriggered() {
        dismissEyeCare()
        exitStateMachine?.forceReset()
    }

    // 处理延迟触发
    private func handleDelayTriggered() {
        let delayMinutes = settings?.delayDurationMinutes ?? 5
        delayBreak(minutes: delayMinutes)
        exitStateMachine?.forceReset()
    }

    // 退出应用
    func quitApp() {
        if showEyeCare {
            exitFullScreenEyeCareMode()
        }

        stopProtection()

        eyeCareTimer?.reset()

        settings?.isProtectionRunning = false
        settings?.lastWorkStartTime = nil

        NSApplication.shared.terminate(nil)
    }

    // 安全地设置应用呈现选项
    private func setAppPresentationOptions(_ options: NSApplication.PresentationOptions) {
        DispatchQueue.main.async {
            do {
                NSApp.presentationOptions = options
            } catch {}
        }
    }

    private func closeAllEyeCareWindows() {
        _ = eyeCareWindows.count
        for window in eyeCareWindows {
            window.close()
        }
        eyeCareWindows.removeAll()

        let swiftUIWindows = NSApplication.shared.windows.filter {
            $0.title.contains("SaveEye Care") || $0.title.contains("Eye Care")
        }

        for window in swiftUIWindows {
            window.close()
        }
    }

    func ensureEyeCareWindowExists() {}
}
