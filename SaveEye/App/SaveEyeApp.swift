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
                .frame(width: 300, height: 260)
                .onAppear {
                    // 在视图出现时初始化依赖关系
                    appState.initialize(settings: settings, activityMonitor: activityMonitor)
                    appManager.initialize(appState: appState, settings: settings, activityMonitor: activityMonitor)
                }
        }
        .windowStyle(.hiddenTitleBar)
        
        // 护眼窗口现在通过程序化方式创建，这里保留一个隐藏的窗口作为备用
        WindowGroup("SaveEye Care", id: "eyecare") {
            // 空的占位符视图，实际护眼窗口通过 AppState 程序化创建
            Rectangle()
                .fill(Color.clear)
                .frame(width: 1, height: 1)
                .opacity(0)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
