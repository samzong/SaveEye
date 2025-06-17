//
//  SaveEyeApp.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import SwiftUI

@main
struct SaveEyeApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var appState = AppState()
    @StateObject private var activityMonitor = ActivityMonitor()
    @StateObject private var appManager = AppManager.shared

    var body: some Scene {
        // 配置窗口（启动时显示）
        WindowGroup("SaveEye Config", id: "config") {
            ConfigWindow()
                .environmentObject(settings)
                .environmentObject(appState)
                .environmentObject(activityMonitor)
                .frame(width: 360, height: 622)
                .onAppear {
                    // 在视图出现时初始化依赖关系
                    appState.initialize(settings: settings, activityMonitor: activityMonitor)
                    appManager.initialize(appState: appState, settings: settings, activityMonitor: activityMonitor)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
