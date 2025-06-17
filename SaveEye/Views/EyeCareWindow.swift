//
//  EyeCareWindow.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import AppKit
import SwiftUI

struct SceneryConfig {
    let name: String
    let sfSymbol: String
    let baseColor: Color
    let description: String
}

struct EyeCareWindow: View {
    @EnvironmentObject var appState: AppState
    @State private var currentImageIndex = 0
    @State private var remainingTime: TimeInterval = 0
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
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    sceneryConfigs[currentImageIndex].baseColor,
                    Color.black.opacity(0.9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 60) {
                VStack(spacing: 20) {
                    Text("护眼休息时间")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("看向远方，放松眼部肌肉")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }

                VStack(spacing: 40) {
                    Image(systemName: sceneryConfigs[currentImageIndex].sfSymbol)
                        .font(.system(size: 240))
                        .foregroundColor(.white.opacity(0.8))
                        .scaleEffect(breathingScale)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathingScale)

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

            MovingDotGuide()
                .opacity(0.6)

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

            VStack {
                Spacer()
                Text("连按 ESC 键三次退出程序")
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
        breathingScale = 1.2

        sceneTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
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

struct MovingDotGuide: View {
    @State private var dotPosition: CGPoint = .init(x: 200, y: 200)
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
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.5)) {
                dotPosition = CGPoint(
                    x: Double.random(in: 150 ... 950),
                    y: Double.random(in: 150 ... 650)
                )
            }
        }
    }
}
