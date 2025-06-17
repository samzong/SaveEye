import Combine
import Dispatch
import Foundation

class EyeCareTimer: ObservableObject {
    @Published var isActive = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var workDuration: TimeInterval = 0
    @Published var shouldShowEyeCare = false

    private var timer: DispatchSourceTimer?
    private var settings: Settings
    private var activityMonitor: ActivityMonitor
    private var cancellables = Set<AnyCancellable>()

    private let inactivityThreshold: TimeInterval = 30

    init(settings: Settings, activityMonitor: ActivityMonitor) {
        self.settings = settings
        self.activityMonitor = activityMonitor

        activityMonitor.$lastActivityTime
            .sink { _ in
            }
            .store(in: &cancellables)

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

        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            self?.updateTimer()
        }
        timer?.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isActive = false
        workDuration = 0
        timeRemaining = 0
        shouldShowEyeCare = false
    }

    func reset() {
        guard isActive else { return }

        shouldShowEyeCare = false
        workDuration = 0
        updateTimerInterval()
    }

    func delayBreak(minutes: Int) {
        guard isActive else { return }

        let delaySeconds = TimeInterval(minutes * 60)
        timeRemaining += delaySeconds
        shouldShowEyeCare = false
    }

    func resumeFromElapsed(_ elapsedSeconds: TimeInterval) {
        guard !isActive else { return }

        isActive = true
        workDuration = elapsedSeconds
        updateTimerInterval()
        shouldShowEyeCare = false

        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            self?.updateTimer()
        }
        timer?.resume()
    }

    private func updateTimerInterval() {
        let intervalSeconds = TimeInterval(settings.breakIntervalMinutes * 60)
        timeRemaining = intervalSeconds - workDuration
    }

    private func updateTimer() {
        let timeSinceLastActivity = activityMonitor.timeSinceLastActivity

        if timeSinceLastActivity < inactivityThreshold {
            workDuration += 1
            timeRemaining = max(0, TimeInterval(settings.breakIntervalMinutes * 60) - workDuration)

            if timeRemaining <= 0 && !shouldShowEyeCare {
                shouldShowEyeCare = true
            }
        } else {}
    }

    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var statusDescription: String {
        if !isActive {
            return "Timer not started"
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
