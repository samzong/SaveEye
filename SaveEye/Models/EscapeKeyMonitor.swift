//
//  EscapeKeyMonitor.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import ApplicationServices
import Foundation

class EscapeKeyMonitor: ObservableObject {
    @Published var isActive = false

    private var eventTap: CFMachPort?

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isActive else {
            return
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, refcon in
                guard refcon != nil else { return Unmanaged.passUnretained(event) }

                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    if keyCode == 53 {
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

    func stopMonitoring() {
        guard isActive, let eventTap = eventTap else { return }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFMachPortInvalidate(eventTap)
        self.eventTap = nil
        isActive = false
    }
}
