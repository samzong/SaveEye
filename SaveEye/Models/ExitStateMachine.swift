//
//  ExitStateMachine.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Foundation
import Combine
import Carbon

// ESC连击退出状态机 - 渐进式退出逻辑
class ExitStateMachine: ObservableObject {
    @Published var currentState: ExitState = .idle
    @Published var pressCount: Int = 0
    @Published var showMessage: String = ""
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // 连击时间窗口（秒）
    private let clickWindow: TimeInterval = 2.0
    
    // 退出状态枚举
    enum ExitState {
        case idle           // 空闲状态
        case firstPress     // 第一次按下ESC
        case secondPress    // 第二次按下ESC
        case thirdPress     // 第三次按下ESC（触发退出）
        case delayRequest   // 延迟请求状态
    }
    
    init() {
        setupStateObserver()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // 处理ESC按键事件
    func handleEscapePress() {
        switch currentState {
        case .idle:
            enterFirstPress()
        case .firstPress:
            enterSecondPress()
        case .secondPress:
            enterThirdPress()
        case .delayRequest:
            // 延迟状态下的ESC按下，增加延迟时间
            handleDelayEscape()
        case .thirdPress:
            // 已经是第三次，保持状态
            break
        }
    }
    
    // 第一次ESC按下
    private func enterFirstPress() {
        currentState = .firstPress
        pressCount = 1
        showMessage = "再按2次ESC键可退出护眼模式"
        startClickTimer()
        
        print("ExitStateMachine: 第一次ESC - \(showMessage)")
    }
    
    // 第二次ESC按下
    private func enterSecondPress() {
        currentState = .secondPress
        pressCount = 2
        showMessage = "再按1次ESC键可退出护眼模式"
        restartClickTimer()
        
        print("ExitStateMachine: 第二次ESC - \(showMessage)")
    }
    
    // 第三次ESC按下（触发退出）
    private func enterThirdPress() {
        currentState = .thirdPress
        pressCount = 3
        showMessage = "正在退出护眼模式..."
        
        timer?.invalidate()
        timer = nil
        
        print("ExitStateMachine: 第三次ESC - 触发退出")
        
        // 延迟一下让用户看到消息，然后触发退出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.triggerExit()
        }
    }
    
    // 延迟状态下的ESC处理
    private func handleDelayEscape() {
        // 在延迟状态下按ESC，增加5分钟延迟
        showMessage = "延迟5分钟，继续工作..."
        
        print("ExitStateMachine: 延迟状态ESC - 增加5分钟延迟")
        
        // 延迟一下让用户看到消息，然后触发延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerDelay()
        }
    }
    
    // 启动连击计时器
    private func startClickTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: clickWindow, repeats: false) { [weak self] _ in
            self?.resetToIdle()
        }
    }
    
    // 重启连击计时器
    private func restartClickTimer() {
        startClickTimer()
    }
    
    // 重置到空闲状态
    private func resetToIdle() {
        currentState = .idle
        pressCount = 0
        showMessage = ""
        timer?.invalidate()
        timer = nil
        
        print("ExitStateMachine: 重置到空闲状态")
    }
    
    // 进入延迟请求状态
    func enterDelayState() {
        currentState = .delayRequest
        pressCount = 0
        showMessage = "是否需要延迟休息？按ESC延迟5分钟"
        
        // 10秒后自动退出延迟状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.currentState == .delayRequest {
                self.resetToIdle()
            }
        }
        
        print("ExitStateMachine: 进入延迟状态")
    }
    
    // 强制重置（用于护眼窗口关闭时）
    func forceReset() {
        resetToIdle()
    }
    
    // 状态观察器
    private func setupStateObserver() {
        $currentState
            .sink { state in
                print("ExitStateMachine: 状态变更为 \(state)")
            }
            .store(in: &cancellables)
    }
    
    // 触发退出回调
    private func triggerExit() {
        NotificationCenter.default.post(name: .exitStateMachineDidTriggerExit, object: nil)
    }
    
    // 触发延迟回调
    private func triggerDelay() {
        NotificationCenter.default.post(name: .exitStateMachineDidTriggerDelay, object: nil)
        resetToIdle()
    }
    
    // 获取状态描述
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
    
    // 是否显示消息
    var shouldShowMessage: Bool {
        return !showMessage.isEmpty
    }
}

// 通知名称扩展
extension Notification.Name {
    static let exitStateMachineDidTriggerExit = Notification.Name("ExitStateMachineDidTriggerExit")
    static let exitStateMachineDidTriggerDelay = Notification.Name("ExitStateMachineDidTriggerDelay")
}
