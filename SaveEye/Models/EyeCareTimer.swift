import Foundation
import Combine
import Dispatch

// 护眼计时器 - 管理工作时间和休息提醒
class EyeCareTimer: ObservableObject {
    @Published var isActive = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var workDuration: TimeInterval = 0
    @Published var shouldShowEyeCare = false
    
    private var timer: DispatchSourceTimer?
    private var settings: Settings
    private var activityMonitor: ActivityMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // 无活动暂停阈值（30秒）
    private let inactivityThreshold: TimeInterval = 30
    
    init(settings: Settings, activityMonitor: ActivityMonitor) {
        self.settings = settings
        self.activityMonitor = activityMonitor
        
        // 监听活动时间变化（实时同步）
        activityMonitor.$lastActivityTime
            .sink { _ in
                // ActivityMonitor 检测到活动时会自动更新 lastActivityTime
                // 这里不需要额外处理，updateTimer() 会读取最新值
            }
            .store(in: &cancellables)
        
        // 监听设置变化，更新计时器间隔
        settings.$breakIntervalMinutes
            .sink { [weak self] _ in
                self?.updateTimerInterval()
            }
            .store(in: &cancellables)
        
        updateTimerInterval()
    }
    
    deinit {
        stop()
    }
    
    // 开始计时
    func start() {
        guard !isActive else { return }
        
        isActive = true
        workDuration = 0
        updateTimerInterval()
        shouldShowEyeCare = false
        
        // 使用 DispatchSourceTimer 替代 Timer，提高性能
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            self?.updateTimer()
        }
        timer?.resume()
        
    }
    
    // 停止计时
    func stop() {
        timer?.cancel()
        timer = nil
        isActive = false
        workDuration = 0
        timeRemaining = 0
        shouldShowEyeCare = false
        
    }
    
    // 重置计时器（护眼结束后调用）
    func reset() {
        guard isActive else { return }
        
        // 先设置标志位防止重复触发
        shouldShowEyeCare = false
        workDuration = 0
        updateTimerInterval()
        
    }
    
    // 延迟休息（用户想继续工作时）
    func delayBreak(minutes: Int) {
        guard isActive else { return }
        
        let delaySeconds = TimeInterval(minutes * 60)
        timeRemaining += delaySeconds
        shouldShowEyeCare = false
        
    }
    
    // 从已运行的时间恢复计时器
    func resumeFromElapsed(_ elapsedSeconds: TimeInterval) {
        guard !isActive else { return }
        
        isActive = true
        workDuration = elapsedSeconds
        updateTimerInterval()
        shouldShowEyeCare = false
        
        // 使用 DispatchSourceTimer 替代 Timer，提高性能
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            self?.updateTimer()
        }
        timer?.resume()
        
    }
    
    // 更新计时器间隔
    private func updateTimerInterval() {
        let intervalSeconds = TimeInterval(settings.breakIntervalMinutes * 60)
        timeRemaining = intervalSeconds - workDuration
    }
    
    // 计时器更新逻辑
    private func updateTimer() {
        // 直接使用 ActivityMonitor 的活动时间
        let timeSinceLastActivity = activityMonitor.timeSinceLastActivity
        
        // 检查是否有用户活动
        if timeSinceLastActivity < inactivityThreshold {
            // 有活动，继续计时
            workDuration += 1
            timeRemaining = max(0, TimeInterval(settings.breakIntervalMinutes * 60) - workDuration)
            
            
            // 检查是否到达休息时间
            if timeRemaining <= 0 && !shouldShowEyeCare {
                shouldShowEyeCare = true
            }
        } else {
        }
    }
    
    // 恢复计时（从暂停状态）
    private func resumeIfNeeded() {
        // 当检测到活动时自动恢复，无需特殊处理
        // updateTimer() 会自动处理活动状态
    }
    
    // 格式化显示剩余时间
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    

    
    // 计时器状态描述
    var statusDescription: String {
        if !isActive {
            return "计时器未启动"
        }
        
        if shouldShowEyeCare {
            return "休息时间"
        }
        
        let timeSinceLastActivity = activityMonitor.timeSinceLastActivity
        if timeSinceLastActivity >= inactivityThreshold {
            return "暂停中（无活动）"
        }
        
        return "工作中 - 剩余 \(formattedTimeRemaining)"
    }
}