//
//  AppManager.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Foundation
import SwiftUI
import AppKit

// 应用管理器 - 处理应用生命周期和窗口管理
class AppManager: ObservableObject {
    static let shared = AppManager()
    
    @Published var isConfigWindowVisible = false
    
    private var appState: AppState?
    private var settings: Settings?
    private var activityMonitor: ActivityMonitor?
    private var appDelegate: AppDelegate?
    private var configWindowDelegate: ConfigWindowDelegate?
    
    private init() {
        setupAppBehavior()
    }
    
    func initialize(appState: AppState, settings: Settings, activityMonitor: ActivityMonitor) {
        self.appState = appState
        self.settings = settings
        self.activityMonitor = activityMonitor
        
        // 初始显示配置窗口
        showConfigWindow()
    }
    
    private func setupAppBehavior() {
        // 防止应用在所有窗口关闭时退出
        appDelegate = AppDelegate()
        NSApp.delegate = appDelegate
    }
    
    func showConfigWindow() {
        isConfigWindowVisible = true
        appState?.showConfigWindow()
    }
    
    func hideConfigWindow() {
        isConfigWindowVisible = false
        appState?.hideConfig()
    }
    
    func createConfigWindow() -> NSWindow? {
        guard let appState = appState, 
              let settings = settings, 
              let activityMonitor = activityMonitor else {
            return nil
        }
        
        let contentView = ConfigWindow()
            .environmentObject(settings)
            .environmentObject(appState)
            .environmentObject(activityMonitor)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        window.title = "SaveEye"
        window.isReleasedWhenClosed = false
        window.center()
        
        // 窗口关闭时隐藏而不是销毁
        configWindowDelegate = ConfigWindowDelegate(appManager: self)
        window.delegate = configWindowDelegate
        
        return window
    }
}

// 应用代理 - 防止应用退出
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 关键：防止最后一个窗口关闭时应用退出
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用启动完成后的额外设置
        NSApp.setActivationPolicy(.accessory) // 设置为后台应用模式
    }
}

// 配置窗口代理
class ConfigWindowDelegate: NSObject, NSWindowDelegate {
    private weak var appManager: AppManager?
    
    init(appManager: AppManager) {
        self.appManager = appManager
    }
    
    func windowWillClose(_ notification: Notification) {
        appManager?.hideConfigWindow()
    }
}