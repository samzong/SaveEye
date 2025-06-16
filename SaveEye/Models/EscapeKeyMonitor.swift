//
//  EscapeKeyMonitor.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Foundation
import ApplicationServices

// 专门的ESC键监听器 - 只在护眼窗口时启用
class EscapeKeyMonitor: ObservableObject {
    @Published var isActive = false
    
    private var eventTap: CFMachPort?
    
    deinit {
        stopMonitoring()
    }
    
    // 开始监听ESC键
    func startMonitoring() {
        guard !isActive else {
            return
        }
        
        // 只监听键盘按下事件
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                
                // 检查ESC键按下
                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    if keyCode == 53 { // ESC键的键码
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .escapeKeyPressed, object: nil)
                        }
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault, eventTap, 0
        )
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isActive = true
    }
    
    // 停止监听ESC键
    func stopMonitoring() {
        guard isActive, let eventTap = eventTap else { return }
        
        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFMachPortInvalidate(eventTap)
        self.eventTap = nil
        isActive = false
        
    }
}