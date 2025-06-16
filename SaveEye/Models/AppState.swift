//
//  AppState.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var showConfig = true      // 启动时显示配置窗口
    @Published var isRunning = false      // 护眼保护是否正在运行
    @Published var showEyeCare = false    // 是否显示护眼窗口

    // 计时器和监控器实例
    private var eyeCareTimer: EyeCareTimer?
    private var activityMonitor: ActivityMonitor?
    private var exitStateMachine: ExitStateMachine?
    private var escapeKeyMonitor: EscapeKeyMonitor?
    private var settings: Settings?
    private var eyeCareWindows: [NSWindow] = []
    private var cancellables = Set<AnyCancellable>()
    
    // 初始化方法
    func initialize(settings: Settings, activityMonitor: ActivityMonitor) {
        self.settings = settings
        self.activityMonitor = activityMonitor
        self.eyeCareTimer = EyeCareTimer(settings: settings, activityMonitor: activityMonitor)
        self.exitStateMachine = ExitStateMachine()
        self.escapeKeyMonitor = EscapeKeyMonitor()
        
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
            // 如果之前在运行，恢复运行状态但不直接触发护眼窗口
            // 用户启动应用的目的是进入配置窗口，而不是立即进入护眼模式
            isRunning = true
            activityMonitor?.startMonitoring()
            
            // 恢复计时器（考虑已经过去的时间）
            if let lastStartTime = settings.lastWorkStartTime {
                let elapsed = Date().timeIntervalSince(lastStartTime)
                let intervalSeconds = TimeInterval(settings.breakIntervalMinutes * 60)
                
                if elapsed < intervalSeconds {
                    // 还在工作时间内，继续计时
                    eyeCareTimer?.resumeFromElapsed(elapsed)
                } else {
                    // 已经超过工作时间，但不直接显示护眼窗口
                    // 让用户在配置窗口中看到状态并决定下一步操作
                    eyeCareTimer?.reset()
                    settings.lastWorkStartTime = Date()
                    eyeCareTimer?.start()
                }
            } else {
                // 重新开始计时
                eyeCareTimer?.start()
                settings.lastWorkStartTime = Date()
            }
            
            print("AppState: 恢复运行状态，护眼保护已启动")
        }
    }

    // 应用状态控制
    func startProtection() {
        isRunning = true
        
        // 保存运行状态
        settings?.isProtectionRunning = true
        settings?.lastWorkStartTime = Date()
        
        // 不自动隐藏配置窗口，让用户自己决定是否关闭
        // hideConfig() // 已移除
        
        // 启动活动监控和计时器
        activityMonitor?.startMonitoring()
        eyeCareTimer?.start()
        
        print("AppState: 护眼保护已启动")
    }

    func stopProtection() {
        isRunning = false
        showEyeCare = false
        
        // 清除运行状态
        settings?.isProtectionRunning = false
        settings?.lastWorkStartTime = nil
        
        // 停止活动监控和计时器
        activityMonitor?.stopMonitoring()
        eyeCareTimer?.stop()
        
        // 完全重置计时器状态
        eyeCareTimer?.reset()
        
        print("AppState: 护眼保护已停止，计时器已重置")
    }

    func hideConfig() {
        showConfig = false
        // 隐藏配置窗口，但不关闭应用
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "config" }) {
                window.close()
            }
        }
    }

    func showConfigWindow() {
        showConfig = true
        // 重新显示配置窗口，但不重置应用状态
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
        
        print("AppState: 护眼窗口显示，启动ESC监听")
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
        print("AppState: 护眼窗口关闭，停止ESC监听")
    }
    
    // 进入真正的全屏护眼模式
    private func enterFullScreenEyeCareMode() {
        // 隐藏 Dock 和菜单栏 - 使用安全的设置方法
        setAppPresentationOptions([.hideDock, .hideMenuBar, .disableAppleMenu, .disableProcessSwitching, .disableHideApplication])
        
        // 为每个显示器创建真正的全屏窗口
        createFullScreenEyeCareWindows()
        
        print("AppState: 已进入真正的全屏护眼模式")
    }
    
    // 退出全屏护眼模式
    private func exitFullScreenEyeCareMode() {
        // 关闭所有护眼窗口
        closeAllEyeCareWindows()
        
        // 恢复正常的系统 UI - 使用安全的设置方法
        setAppPresentationOptions([])
        
        print("AppState: 已退出全屏护眼模式")
    }
    
    // 创建真正的全屏护眼窗口
    private func createFullScreenEyeCareWindows() {
        let screens = NSScreen.screens
        print("AppState: 检测到 \(screens.count) 个显示器")
        
        // 清理之前的窗口
        closeAllEyeCareWindows()
        
        for (index, screen) in screens.enumerated() {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            // 设置窗口属性 - 真正的全屏覆盖
            window.level = NSWindow.Level.screenSaver  // 使用屏保级别，确保覆盖所有内容
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenDisallowsTiling]
            window.isReleasedWhenClosed = false
            window.backgroundColor = NSColor.black
            window.isOpaque = true  // 设为不透明，确保完全覆盖
            window.hasShadow = false
            window.ignoresMouseEvents = false
            
            // 强制设置窗口覆盖整个屏幕，包括菜单栏和 Dock 区域
            let fullFrame = screen.frame
            window.setFrame(fullFrame, display: true)
            
            // 创建 SwiftUI 内容
            let contentView = EyeCareWindow()
                .environmentObject(self)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)  // 确保背景完全黑色
            
            window.contentView = NSHostingView(rootView: contentView)
            
            // 确保窗口在指定屏幕上显示
            window.setFrameOrigin(screen.frame.origin)
            window.makeKeyAndOrderFront(nil)
            
            // 保存窗口引用
            eyeCareWindows.append(window)
            
            print("AppState: 在显示器 \(index + 1) 创建全屏护眼窗口 (\(Int(screen.frame.width))x\(Int(screen.frame.height)))")
        }
        
        // 激活应用并确保窗口在最前面
        NSApp.activate(ignoringOtherApps: true)
        
        // 额外确保覆盖所有内容
        if let mainWindow = eyeCareWindows.first {
            mainWindow.level = NSWindow.Level.screenSaver
            mainWindow.orderFrontRegardless()
        }
        
        print("AppState: 所有显示器的全屏护眼窗口已创建")
    }
    
    // 延迟休息
    func delayBreak(minutes: Int = 5) {
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
    
    var workProgress: Double {
        return eyeCareTimer?.workProgress ?? 0.0
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
        print("AppState: 退出状态机触发退出")
        dismissEyeCare()
        exitStateMachine?.forceReset()
    }
    
    // 处理延迟触发
    private func handleDelayTriggered() {
        print("AppState: 退出状态机触发延迟")
        delayBreak(minutes: 5)
        exitStateMachine?.forceReset()
    }

    // 退出应用
    func quitApp() {
        // 确保退出前恢复系统 UI
        if showEyeCare {
            exitFullScreenEyeCareMode()
        }
        
        // 完全清除所有状态和计时器
        stopProtection()
        
        // 额外确保计时器完全重置
        eyeCareTimer?.reset()
        
        // 清除所有持久化状态
        settings?.isProtectionRunning = false
        settings?.lastWorkStartTime = nil
        
        print("AppState: 应用退出前已清除所有状态")
        NSApplication.shared.terminate(nil)
    }

    // 安全地设置应用呈现选项
    private func setAppPresentationOptions(_ options: NSApplication.PresentationOptions) {
        DispatchQueue.main.async {
            do {
                NSApp.presentationOptions = options
                print("AppState: 成功设置呈现选项: \(options)")
            } catch {
                print("AppState: 设置呈现选项失败: \(error)")
            }
        }
    }

    // 窗口管理辅助方法
    func closeConfigWindow() {
        // 关闭配置窗口
        if let window = NSApplication.shared.windows.first(where: {
$0.title.contains("Config") }) {
            window.close()
        }
    }

    // 清理所有护眼窗口的辅助方法
    
    private func closeAllEyeCareWindows() {
        let windowCount = eyeCareWindows.count
        for window in eyeCareWindows {
            window.close()
        }
        eyeCareWindows.removeAll()
        
        // 也尝试关闭可能存在的 SwiftUI 窗口
        let swiftUIWindows = NSApplication.shared.windows.filter {
            $0.title.contains("SaveEye Care") || $0.title.contains("Eye Care")
        }
        
        for window in swiftUIWindows {
            window.close()
        }
        
        print("AppState: 清理了 \(windowCount) 个护眼窗口和 \(swiftUIWindows.count) 个 SwiftUI 窗口")
    }
    
    func ensureEyeCareWindowExists() {
        // 确保护眼窗口存在，如果不存在则尝试创建
        print("AppState: 检查护眼窗口是否存在")
        
        let hasEyeCareWindow = NSApplication.shared.windows.contains { window in
            window.title.contains("SaveEye Care") || 
            window.title.contains("Eye Care") || 
            window.identifier?.rawValue == "eyecare"
        }
        
        if !hasEyeCareWindow {
            print("AppState: 护眼窗口不存在，尝试通过环境打开")
            // 尝试通过环境变量或其他方式触发窗口创建
            NSApp.sendAction(#selector(NSApplication.arrangeInFront(_:)), to: nil, from: nil)
        } else {
            print("AppState: 护眼窗口已存在")
        }
    }
}
