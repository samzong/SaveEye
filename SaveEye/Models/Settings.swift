//
//  Settings.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//
import Foundation
import Combine
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
        // 从UserDefaults读取设置，默认值：20分钟，开启自启动
        self.breakIntervalMinutes = UserDefaults.standard.object(forKey:
"breakIntervalMinutes") as? Int ?? 20
        // 默认休息时间20秒
        self.restDurationSeconds = UserDefaults.standard.object(forKey: "restDurationSeconds") as? Int ?? 20
        // 默认延迟时间5分钟  
        self.delayDurationMinutes = UserDefaults.standard.object(forKey: "delayDurationMinutes") as? Int ?? 5
        self.autoStart = UserDefaults.standard.object(forKey: "autoStart") as? Bool
 ?? true
        
        // 读取运行状态
        self.isProtectionRunning = UserDefaults.standard.bool(forKey: "isProtectionRunning")
        self.lastWorkStartTime = UserDefaults.standard.object(forKey: "lastWorkStartTime") as? Date

        // 确保间隔为正值（方便测试，允许小值）
        if breakIntervalMinutes < 1 { breakIntervalMinutes = 1 }
        if restDurationSeconds < 5 { restDurationSeconds = 5 }
        if delayDurationMinutes < 1 { delayDurationMinutes = 1 }
    }

    private func updateAutoStart() {
        // 更新开机自启动设置
        if autoStart {
            enableAutoStart()
        } else {
            disableAutoStart()
        }
    }

    private func enableAutoStart() {
        // 使用 SMAppService 设置开机自启动
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.register()
            } else {
                // 对于 macOS 12，暂时跳过自启动设置
            }
        } catch {
        }
    }

    private func disableAutoStart() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.unregister()
            } else {
                // 对于 macOS 12，暂时跳过自启动设置
            }
        } catch {
        }
    }
}
