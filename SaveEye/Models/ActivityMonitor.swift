//
//  ActivityMonitor.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Foundation
import ApplicationServices
import Combine

class ActivityMonitor: ObservableObject {
    @Published var isActive = false
    @Published var lastActivityTime = Date()
    @Published var hasPermission = false

    private var eventTap: CFMachPort?
    private var checkPermissionTimer: Timer?

    init() {
        checkPermission()
        startPermissionMonitoring()
    }

    deinit {
        stopMonitoring()
        checkPermissionTimer?.invalidate()
    }

    // MARK: - 权限管理

    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }

    func requestPermission() {
        let options: [String: Any] = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func startPermissionMonitoring() {
        // 定期检查权限状态（每5秒）
        checkPermissionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.checkPermission()
            }
        }
    }

    // MARK: - 活动监控

    func startMonitoring() {
        guard hasPermission else {
            print("ActivityMonitor: No accessibility permission")
            return
        }

        guard !isActive else {
            print("ActivityMonitor: Already monitoring")
            return
        }

        // 监听用户活动（包括键盘活动用于计时，但不处理ESC键）
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.mouseMoved.rawValue) |
                       (1 << CGEventType.leftMouseDown.rawValue) |
                       (1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }

                let monitor = Unmanaged<ActivityMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.recordActivity()

                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            print("ActivityMonitor: Failed to create event tap")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault, eventTap, 0
        )
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isActive = true
        print("ActivityMonitor: Started monitoring")
    }

    func stopMonitoring() {
        guard isActive, let eventTap = eventTap else { return }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFMachPortInvalidate(eventTap)
        self.eventTap = nil
        isActive = false

        print("ActivityMonitor: Stopped monitoring")
    }

    private func recordActivity() {
        DispatchQueue.main.async {
            self.lastActivityTime = Date()
        }
    }

    // MARK: - 便捷方法

    var timeSinceLastActivity: TimeInterval {
        Date().timeIntervalSince(lastActivityTime)
    }

    func isUserActive(threshold: TimeInterval = 10.0) -> Bool {
        timeSinceLastActivity < threshold
    }
}

// 通知名称扩展
extension Notification.Name {
    static let escapeKeyPressed = Notification.Name("EscapeKeyPressed")
}
