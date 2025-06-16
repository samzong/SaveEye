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
        VStack(spacing: 24) {
            // 应用头部
            headerView
            
            // 主要设置卡片
            VStack(spacing: 20) {
                // 护眼保护开关
                protectionToggleCard
                
                Divider()
                    .padding(.horizontal, -20)
                
                // 休息间隔设置
                breakIntervalCard
                
                Divider()
                    .padding(.horizontal, -20)
                
                // 开机自启动
                autoStartCard
            }
            .padding(20)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            
            // 底部操作按钮
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
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // 应用图标和名称 - 居中布局
            VStack(spacing: 8) {
                // 使用应用的真实logo
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                VStack(spacing: 2) {
                    Text("SaveEye")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Text("智能护眼助手")
                    //     .font(.caption)
                    //     .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var protectionToggleCard: some View {
        HStack(spacing: 16) {
            // 状态指示器
            Circle()
                .fill(appState.isRunning ? .green : .red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.isRunning ? "护眼保护已启动" : "护眼保护已关闭")
                    .font(.body)
                    .fontWeight(.medium)
                
                // 始终显示状态文本区域，保持布局稳定
                Text(appState.isRunning ? appState.timerStatus : " ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 12) // 确保最小高度
            }
            
            Spacer()
            
            // 大型开关
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
                    in: 5...60,
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
                
                // 当前值显示
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
            
            // 建议文案
            Text("建议设置为 20-30 分钟，有效缓解眼部疲劳")
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
    
    // MARK: - 私有方法
    
    private func startProtection() {
        // 检查权限
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermission()
            return
        }
        
        // 启动保护
        appState.startProtection()
    }
    
    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {
            print("Accessibility permission not granted yet")
        }
    }
    
    private func setupWindowStyle() {
        // 设置窗口样式，禁用最小化和最大化按钮
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.title.contains("SaveEye") }) {
                // 移除最小化和最大化按钮的功能
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                window.standardWindowButton(.zoomButton)?.isEnabled = false
                
                // 设置窗口为不可调整大小
                window.styleMask.remove(.resizable)
                
                print("ConfigWindow: 窗口样式已设置 - 禁用最小化和最大化")
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

// 预览支持
struct ConfigWindow_Previews: PreviewProvider {
    static var previews: some View {
        ConfigWindow()
            .environmentObject(Settings())
            .environmentObject(AppState())
    }
}
