//
//  Settings.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//
import Combine
import Foundation
import ServiceManagement

class Settings: ObservableObject {
    @Published var breakIntervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(breakIntervalMinutes, forKey:
                "breakIntervalMinutes")
        }
    }

    // 休息时间（秒）
    @Published var restDurationSeconds: Int {
        didSet {
            UserDefaults.standard.set(restDurationSeconds, forKey: "restDurationSeconds")
        }
    }

    // 延迟休息时间（分钟）
    @Published var delayDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(delayDurationMinutes, forKey: "delayDurationMinutes")
        }
    }

    @Published var autoStart: Bool {
        didSet {
            UserDefaults.standard.set(autoStart, forKey: "autoStart")
            updateAutoStart()
        }
    }

    // 运行状态持久化
    @Published var isProtectionRunning: Bool {
        didSet {
            UserDefaults.standard.set(isProtectionRunning, forKey: "isProtectionRunning")
        }
    }

    @Published var lastWorkStartTime: Date? {
        didSet {
            if let date = lastWorkStartTime {
                UserDefaults.standard.set(date, forKey: "lastWorkStartTime")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastWorkStartTime")
            }
        }
    }

    init() {
        breakIntervalMinutes = UserDefaults.standard.object(forKey:
            "breakIntervalMinutes") as? Int ?? 20
        restDurationSeconds = UserDefaults.standard.object(forKey: "restDurationSeconds") as? Int ?? 20
        delayDurationMinutes = UserDefaults.standard.object(forKey: "delayDurationMinutes") as? Int ?? 5
        autoStart = UserDefaults.standard.object(forKey: "autoStart") as? Bool
            ?? true

        isProtectionRunning = UserDefaults.standard.bool(forKey: "isProtectionRunning")
        lastWorkStartTime = UserDefaults.standard.object(forKey: "lastWorkStartTime") as? Date

        if breakIntervalMinutes < 1 { breakIntervalMinutes = 1 }
        if restDurationSeconds < 5 { restDurationSeconds = 5 }
        if delayDurationMinutes < 1 { delayDurationMinutes = 1 }
    }

    private func updateAutoStart() {
        if autoStart {
            enableAutoStart()
        } else {
            disableAutoStart()
        }
    }

    private func enableAutoStart() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.register()
            } else {}
        } catch {}
    }

    private func disableAutoStart() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.unregister()
            } else {}
        } catch {}
    }
}
