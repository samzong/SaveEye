//
//  ConfigWindow.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import SwiftUI
import ApplicationServices

struct ConfigWindow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var activityMonitor: ActivityMonitor

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "eye.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("SaveEye")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Divider()

            // 状态显示
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(appState.isRunning ? .green : .red)
                        .frame(width: 12, height: 12)

                    Text(appState.isRunning ? "护眼保护已启动" : "护眼保护已关闭")
                        .font(.body)

                    Spacer()
                }
                
                if appState.isRunning {
                    VStack(spacing: 4) {
                        HStack {
                            Text("状态:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appState.timerStatus)
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // 进度条
                        ProgressView(value: appState.workProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(x: 1, y: 0.5)
                    }
                }
            }

            // 设置选项
            VStack(spacing: 12) {
                HStack {
                    Text("休息间隔:")
                        .frame(width: 70, alignment: .leading)
                    Spacer()
                    HStack {
                        TextField("", value: $settings.breakIntervalMinutes,
formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 45)

                        Text("分钟")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("建议: 1-60 分钟 (测试可用更小值)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Toggle("开机自启动", isOn: $settings.autoStart)
            }

            Divider()

            // 操作按钮
            HStack(spacing: 12) {
                if appState.isRunning {
                    Button("停止保护") {
                        stopProtection()
                    }
                    .buttonStyle(BorderedButtonStyle())
                } else {
                    Button("开始保护") {
                        startProtection()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }

                Button("退出应用") {
                    appState.quitApp()
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding(20)
        .frame(width: 220, height: 260)
        .onAppear {
            // 检查权限
            checkAccessibilityPermission()
        }
    }

    // MARK: - 私有方法

    private func startProtection() {
        // 检查权限
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermission()
            return
        }

        // 启动保护
        appState.startProtection()

        // 不自动隐藏配置窗口，让用户自己决定
        // appState.closeConfigWindow() // 已移除
    }

    private func stopProtection() {
        appState.stopProtection()
    }

    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {
            // 如果没有权限，显示提示但不强制要求
            print("Accessibility permission not granted yet")
        }
    }

    private func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "SaveEye 需要辅助功能权限来监控您的活动并提供护眼提醒。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后设置")
        alert.alertStyle = .informational

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 打开系统设置
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// 预览支持
struct ConfigWindow_Previews: PreviewProvider {
    static var previews: some View {
        ConfigWindow()
            .environmentObject(Settings())
            .environmentObject(AppState())
    }
}
