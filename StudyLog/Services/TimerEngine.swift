import Foundation
import Observation

@Observable
final class TimerEngine {
    private(set) var isRunning = false
    private(set) var isPaused = false
    private(set) var startedAt: Date?
    private(set) var pausedAt: Date?
    private(set) var accumulatedPausedSeconds: TimeInterval = 0

    func start() {
        startedAt = Date()
        pausedAt = nil
        accumulatedPausedSeconds = 0
        isRunning = true
        isPaused = false
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        pausedAt = Date()
        isPaused = true
    }

    func resume() {
        guard isRunning, isPaused, let pausedAt else { return }
        accumulatedPausedSeconds += Date().timeIntervalSince(pausedAt)
        self.pausedAt = nil
        isPaused = false
    }

    func elapsedSeconds() -> Int {
        guard let startedAt else { return 0 }

        let now = isPaused ? (pausedAt ?? Date()) : Date()
        let elapsed = now.timeIntervalSince(startedAt) - accumulatedPausedSeconds
        return max(0, Int(elapsed))
    }

    func stop() -> Int {
        let result = elapsedSeconds()
        isRunning = false
        isPaused = false
        startedAt = nil
        pausedAt = nil
        accumulatedPausedSeconds = 0
        return result
    }
}
