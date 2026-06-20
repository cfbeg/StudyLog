import Foundation

enum StatisticsService {
    static func totalSecondsToday(sessions: [StudySession], calendar: Calendar = .current) -> Int {
        sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    static func totalSecondsThisWeek(sessions: [StudySession], calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }

        return sessions
            .filter { week.contains($0.startedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    static func totalSeconds(for subject: Subject, sessions: [StudySession]) -> Int {
        sessions
            .filter { $0.subject?.id == subject.id }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    static func totalSecondsToday(for subject: Subject, sessions: [StudySession], calendar: Calendar = .current) -> Int {
        sessions
            .filter { $0.subject?.id == subject.id && calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    static func totalSecondsThisWeek(for subject: Subject, sessions: [StudySession], calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }

        return sessions
            .filter { $0.subject?.id == subject.id && week.contains($0.startedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    static func totalSeconds(for task: StudyTask) -> Int {
        task.sessions.reduce(0) { $0 + $1.durationSeconds }
    }
}
