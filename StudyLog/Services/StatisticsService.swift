import Foundation

struct SubjectTimeSummary: Identifiable {
    let id: UUID
    let subjectName: String
    let colorHex: String
    let seconds: Int
}

struct DailyTimeSummary: Identifiable {
    let id = UUID()
    let day: Date
    let label: String
    let seconds: Int
}

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

    static func subjectSummariesToday(subjects: [Subject], sessions: [StudySession], calendar: Calendar = .current) -> [SubjectTimeSummary] {
        subjects
            .filter { !$0.isArchived }
            .map { subject in
                SubjectTimeSummary(
                    id: subject.id,
                    subjectName: subject.name,
                    colorHex: subject.colorHex,
                    seconds: totalSecondsToday(for: subject, sessions: sessions, calendar: calendar)
                )
            }
            .filter { $0.seconds > 0 }
            .sorted { $0.seconds > $1.seconds }
    }

    static func dailySummariesForCurrentWeek(sessions: [StudySession], calendar: Calendar = .current) -> [DailyTimeSummary] {
        let now = Date()
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: week.start) else {
                return nil
            }

            let start = calendar.startOfDay(for: day)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start), start < week.end else {
                return nil
            }

            let seconds = sessions
                .filter { $0.startedAt >= start && $0.startedAt < end }
                .reduce(0) { $0 + $1.durationSeconds }

            return DailyTimeSummary(day: start, label: formatter.string(from: start), seconds: seconds)
        }
    }

    static func progressRatio(seconds: Int, goalSeconds: Int) -> Double {
        guard goalSeconds > 0 else { return 0 }
        return min(1, Double(seconds) / Double(goalSeconds))
    }
}
