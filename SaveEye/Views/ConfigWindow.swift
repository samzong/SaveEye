//
//  ConfigWindow.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import ApplicationServices
import SwiftUI

struct ConfigWindow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var activityMonitor: ActivityMonitor

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                protectionToggleCard

                Divider()
                    .padding(.horizontal, -20)

                breakIntervalCard

                Divider()
                    .padding(.horizontal, -20)

                restDurationCard

                Divider()
                    .padding(.horizontal, -20)

                delayDurationCard

                Divider()
                    .padding(.horizontal, -20)

                autoStartCard
            }
            .padding(20)
            .cornerRadius(12)

            Button("退出应用") {
                appState.quitApp()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            checkAccessibilityPermission()
            setupWindowStyle()
        }
    }

    // MARK: - 视图组件

    private var protectionToggleCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(appState.isRunning ? .green : .red)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.isRunning ? "护眼保护已启动" : "护眼保护已关闭")
                    .font(.body)
                    .fontWeight(.medium)

                Text(appState.isRunning ? appState.timerStatus : " ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 12)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { appState.isRunning },
                set: { isOn in
                    if isOn {
                        startProtection()
                    } else {
                        appState.stopProtection()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .scaleEffect(1.2)
        }
    }

    private var breakIntervalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("休息间隔")
                .font(.headline)

            HStack {
                Slider(
                    value: Binding(
                        get: { Double(settings.breakIntervalMinutes) },
                        set: { settings.breakIntervalMinutes = Int($0) }
                    ),
                    in: 5 ... 60,
                    step: 5
                ) {
                    Text("休息间隔")
                } minimumValueLabel: {
                    Text("5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)

                VStack {
                    Text("\(settings.breakIntervalMinutes)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40)

                    Text("分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("建议设置为 20-30 分钟，有效缓解眼部疲劳")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var restDurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("休息时间")
                .font(.headline)

            HStack {
                Slider(
                    value: Binding(
                        get: { Double(settings.restDurationSeconds) },
                        set: { settings.restDurationSeconds = Int($0) }
                    ),
                    in: 10 ... 60,
                    step: 5
                ) {
                    Text("休息时间")
                } minimumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)

                VStack {
                    Text("\(settings.restDurationSeconds)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40)

                    Text("秒")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("建议设置为 20-60 秒，让眼部得到充分休息")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var delayDurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("延迟时间")
                .font(.headline)

            HStack {
                Slider(
                    value: Binding(
                        get: { Double(settings.delayDurationMinutes) },
                        set: { settings.delayDurationMinutes = Int($0) }
                    ),
                    in: 1 ... 10,
                    step: 1
                ) {
                    Text("延迟时间")
                } minimumValueLabel: {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)

                VStack {
                    Text("\(settings.delayDurationMinutes)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40)

                    Text("分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("建议设置为 1-10 分钟，有效缓解眼部疲劳")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var autoStartCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("开机自启动")
                    .font(.body)
                    .fontWeight(.medium)

                Text("应用将在系统启动时自动运行")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $settings.autoStart)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(1.2)
        }
    }

    private func startProtection() {
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermission()
            return
        }

        appState.startProtection()
    }

    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {}
    }

    private func setupWindowStyle() {
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.title.contains("SaveEye") }) {
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                window.standardWindowButton(.zoomButton)?.isEnabled = false

                window.styleMask.remove(.resizable)
            }
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
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

struct ConfigWindow_Previews: PreviewProvider {
    static var previews: some View {
        ConfigWindow()
            .environmentObject(Settings())
            .environmentObject(AppState())
    }
}
