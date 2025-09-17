//
//  AppManager.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import AppKit
import Foundation
import SwiftUI

// 应用管理器 - 处理应用生命周期和窗口管理
@MainActor
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
}

// 应用代理 - 防止应用退出
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_: Notification) {
        // 应用启动完成后的额外设置
        NSApp.setActivationPolicy(.accessory)
    }
}

// 配置窗口代理
class ConfigWindowDelegate: NSObject, NSWindowDelegate {
    private weak var appManager: AppManager?

    init(appManager: AppManager) {
        self.appManager = appManager
    }

    func windowWillClose(_: Notification) {
        Task { @MainActor in
            appManager?.hideConfigWindow()
        }
    }
}
