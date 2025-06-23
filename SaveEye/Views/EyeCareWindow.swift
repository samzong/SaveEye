//
//  EyeCareWindow.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import AppKit
import SwiftUI

struct EyeCareWindow: View {
    @EnvironmentObject var appState: AppState
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var breathingOpacity: Double = 0.8
    @State private var breathingScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 护眼友好的深色渐变背景
            RadialGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.08),
                    Color(red: 0.02, green: 0.05, blue: 0.04)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 800
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 120) {
                // 简洁标题
                Text("护眼休息")
                    .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(8)

                // 中心呼吸引导区域
                VStack(spacing: 80) {
                    // 抽象的视觉引导元素
                    ZStack {
                        // 外圈
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 280, height: 280)
                            .scaleEffect(breathingScale * 1.1)
                            .opacity(breathingOpacity * 0.6)
                        
                        // 中圈
                        Circle()
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                            .frame(width: 200, height: 200)
                            .scaleEffect(breathingScale)
                            .opacity(breathingOpacity * 0.8)
                        
                        // 中心点
                        Circle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: 8, height: 8)
                            .scaleEffect(breathingScale * 0.8)
                            .opacity(breathingOpacity)
                        
                        // 中心引导文字
                        Text("注视远方")
                            .font(.system(size: 18, weight: .light, design: .rounded))
                            .foregroundColor(.green.opacity(0.9))
                            .tracking(4)
                            .offset(y: 60)
                    }
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: breathingScale)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: breathingOpacity)

                    // 时间显示
                    VStack(spacing: 12) {
                        Text(formatTime(remainingTime))
                            .font(.system(size: 64, weight: .ultraLight, design: .monospaced))
                            .foregroundColor(.green.opacity(0.9))
                            .tracking(2)
                    }
                }
            }

            // 退出提示消息（右上角）
            VStack {
                HStack {
                    Spacer()
                    if appState.shouldShowExitMessage {
                        Text(appState.exitStateMessage)
                            .font(.system(size: 16, weight: .light, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(20)
                    }
                }
                .padding(.top, 40)
                .padding(.trailing, 40)
                Spacer()
            }

            // 操作提示（底部）
            VStack {
                Spacer()
                Text("按住 ESC 键退出")
                    .font(.system(size: 14, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            setupEyeCareWindow()
            startBreathingAnimation()
            startEyeCareTimer()
        }
        .onDisappear {
            cleanupTimers()
        }

        .onReceive(NotificationCenter.default.publisher(for: .exitStateMachineDidTriggerDelay)) { _ in
            delayBreak()
        }
    }

    private func setupEyeCareWindow() {
        remainingTime = TimeInterval(appState.settings?.restDurationSeconds ?? 20)
    }

    private func startEyeCareTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                finishBreak()
            }
        }
    }

    private func startBreathingAnimation() {
        // 启动缓慢的呼吸动画
        breathingScale = 1.15
        breathingOpacity = 0.9
    }

    private func delayBreak() {
        let delayMinutes = appState.settings?.delayDurationMinutes ?? 5
        appState.delayBreak(minutes: delayMinutes)
    }

    private func finishBreak() {
        appState.dismissEyeCare()
    }

    private func cleanupTimers() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
