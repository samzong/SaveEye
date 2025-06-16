//
//  EyeCareWindow.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import SwiftUI
import AppKit

// 远景配置结构
struct SceneryConfig {
    let name: String
    let sfSymbol: String
    let baseColor: Color
    let description: String
}

// 全屏护眼窗口
struct EyeCareWindow: View {
    @EnvironmentObject var appState: AppState
    @State private var currentImageIndex = 0
    @State private var remainingTime: TimeInterval = 0 // 护眼时间从设置中获取
    @State private var timer: Timer?
    @State private var breathingScale: CGFloat = 1.0
    @State private var sceneTimer: Timer?
    
    // 远景图像配置
    private let sceneryConfigs = [
        SceneryConfig(
            name: "山景",
            sfSymbol: "mountain.2.fill",
            baseColor: Color.blue.opacity(0.4),
            description: "远山如黛，层峦叠嶂"
        ),
        SceneryConfig(
            name: "森林",
            sfSymbol: "tree.fill", 
            baseColor: Color.green.opacity(0.4),
            description: "绿树成荫，生机盎然"
        ),
        SceneryConfig(
            name: "海洋",
            sfSymbol: "water.waves",
            baseColor: Color.cyan.opacity(0.4),
            description: "碧海蓝天，波澜壮阔"
        ),
        SceneryConfig(
            name: "草原",
            sfSymbol: "leaf.fill",
            baseColor: Color.mint.opacity(0.4),
            description: "绿草如茵，风吹草低"
        ),
        SceneryConfig(
            name: "湖泊",
            sfSymbol: "drop.fill",
            baseColor: Color.teal.opacity(0.4),
            description: "湖光山色，静谧安详"
        )
    ]
    
    var body: some View {
        ZStack {
            // 全屏背景渐变
            LinearGradient(
                colors: [
                    sceneryConfigs[currentImageIndex].baseColor,
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            // 主要内容居中显示
            VStack(spacing: 60) {
                // 护眼提示文字
                VStack(spacing: 20) {
                    Text("护眼休息时间")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("看向远方，放松眼部肌肉")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // 远景图像（大尺寸居中）
                VStack(spacing: 40) {
                    // 主要远景图标
                    Image(systemName: sceneryConfigs[currentImageIndex].sfSymbol)
                        .font(.system(size: 240))
                        .foregroundColor(.white.opacity(0.8))
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathingScale)
                    
                    // 场景名称和描述
                    VStack(spacing: 16) {
                        Text(sceneryConfigs[currentImageIndex].name)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(sceneryConfigs[currentImageIndex].description)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
                // 倒计时显示（超大字号）
                VStack(spacing: 16) {
                    Text("剩余时间")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatTime(remainingTime))
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
            }
            
            // 简单20-20-20引导点
            MovingDotGuide()
                .opacity(0.6)
            
            // 退出提示（右上角）
            VStack {
                HStack {
                    Spacer()
                    if appState.shouldShowExitMessage {
                        Text(appState.exitStateMessage)
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 50)
                .padding(.trailing, 50)
                Spacer()
            }
            
            // 底部ESC提示
            VStack {
                Spacer()
                Text("按 ESC 键三次退出")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
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
        .onReceive(NotificationCenter.default.publisher(for: .exitStateMachineDidTriggerExit)) { _ in
            finishBreak()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exitStateMachineDidTriggerDelay)) { _ in
            delayBreak()
        }
    }
    
    // MARK: - 私有方法
    
    private func setupEyeCareWindow() {
        // 从设置中获取休息时间
        remainingTime = TimeInterval(appState.settings?.restDurationSeconds ?? 20)
    }
    
    private func startEyeCareTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                // 时间到，自动结束
                finishBreak()
            }
        }
    }
    
    private func startBreathingAnimation() {
        breathingScale = 1.2
        
        // 每30秒自动切换场景（降低频率）
        sceneTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                self.switchScene()
            }
        }
    }
    
    private func switchScene() {
        currentImageIndex = (currentImageIndex + 1) % sceneryConfigs.count
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
        sceneTimer?.invalidate()
        sceneTimer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// 简单20-20-20引导点
struct MovingDotGuide: View {
    @State private var dotPosition: CGPoint = CGPoint(x: 200, y: 200)
    @State private var timer: Timer?
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 16, height: 16)
            .position(dotPosition)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .onAppear {
                startMovingDot()
            }
            .onDisappear {
                timer?.invalidate()
            }
    }
    
    private func startMovingDot() {
        // 每4秒移动一次位置，引导用户眼球运动
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.5)) {
                dotPosition = CGPoint(
                    x: Double.random(in: 150...950),
                    y: Double.random(in: 150...650)
                )
            }
        }
    }
}