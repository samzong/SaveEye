//
//  ExitStateMachine.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Carbon
import Combine
import Foundation

class ExitStateMachine: ObservableObject {
    @Published var currentState: ExitState = .idle
    @Published var pressCount: Int = 0
    @Published var showMessage: String = ""

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private weak var settings: Settings?

    private let clickWindow: TimeInterval = 2.0

    enum ExitState {
        case idle
        case firstPress
        case secondPress
        case thirdPress
        case delayRequest
    }

    init(settings: Settings? = nil) {
        self.settings = settings
        setupStateObserver()
    }

    deinit {
        timer?.invalidate()
    }

    func handleEscapePress() {
        switch currentState {
        case .idle:
            enterFirstPress()
        case .firstPress:
            enterSecondPress()
        case .secondPress:
            enterThirdPress()
        case .delayRequest:
            handleDelayEscape()
        case .thirdPress:
            break
        }
    }

    private func enterFirstPress() {
        currentState = .firstPress
        pressCount = 1
        showMessage = "再按2次ESC键可退出护眼模式"
        startClickTimer()
    }

    private func enterSecondPress() {
        currentState = .secondPress
        pressCount = 2
        showMessage = "再按1次ESC键可退出护眼模式"
        restartClickTimer()
    }

    private func enterThirdPress() {
        currentState = .thirdPress
        pressCount = 3
        showMessage = "正在退出护眼模式..."

        timer?.invalidate()
        timer = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.triggerExit()
        }
    }

    private func handleDelayEscape() {
        let delayMinutes = settings?.delayDurationMinutes ?? 5
        showMessage = "延迟\(delayMinutes)分钟，继续工作..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerDelay()
        }
    }

    private func startClickTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: clickWindow, repeats: false) { [weak self] _ in
            self?.resetToIdle()
        }
    }

    private func restartClickTimer() {
        startClickTimer()
    }

    private func resetToIdle() {
        currentState = .idle
        pressCount = 0
        showMessage = ""
        timer?.invalidate()
        timer = nil
    }

    func enterDelayState() {
        currentState = .delayRequest
        pressCount = 0
        let delayMinutes = settings?.delayDurationMinutes ?? 5
        showMessage = "是否需要延迟休息？按ESC延迟\(delayMinutes)分钟"

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.currentState == .delayRequest {
                self.resetToIdle()
            }
        }
    }

    func forceReset() {
        resetToIdle()
    }

    private func setupStateObserver() {
        $currentState
            .sink { _ in }
            .store(in: &cancellables)
    }

    private func triggerExit() {
        NotificationCenter.default.post(name: .exitStateMachineDidTriggerExit, object: nil)
    }

    private func triggerDelay() {
        NotificationCenter.default.post(name: .exitStateMachineDidTriggerDelay, object: nil)
        resetToIdle()
    }

    var stateDescription: String {
        switch currentState {
        case .idle:
            return "空闲"
        case .firstPress:
            return "第一次ESC"
        case .secondPress:
            return "第二次ESC"
        case .thirdPress:
            return "第三次ESC（退出中）"
        case .delayRequest:
            return "延迟请求"
        }
    }

    var shouldShowMessage: Bool {
        return !showMessage.isEmpty
    }
}

extension Notification.Name {
    static let exitStateMachineDidTriggerExit = Notification.Name("ExitStateMachineDidTriggerExit")
    static let exitStateMachineDidTriggerDelay = Notification.Name("ExitStateMachineDidTriggerDelay")
}
