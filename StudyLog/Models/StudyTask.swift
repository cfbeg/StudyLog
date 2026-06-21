import Foundation
import SwiftData

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted:
            return "未着手"
        case .inProgress:
            return "進行中"
        case .completed:
            return "完了"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:
            return "低"
        case .normal:
            return "普通"
        case .high:
            return "高"
        }
    }
}

@Model
final class StudyTask {
    var id: UUID
    var title: String
    var note: String
    var dueDate: Date?
    var estimatedSeconds: Int
    var statusRawValue: String
    var priorityRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    var subject: Subject?

    @Relationship(deleteRule: .nullify, inverse: \StudySession.task)
    var sessions: [StudySession]

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRawValue) ?? .notStarted }
        set {
            statusRawValue = newValue.rawValue
            completedAt = newValue == .completed ? Date() : nil
            updatedAt = Date()
        }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .normal }
        set {
            priorityRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var spentSeconds: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    init(title: String, subject: Subject, estimatedSeconds: Int = 0) {
        self.id = UUID()
        self.title = title
        self.note = ""
        self.dueDate = nil
        self.estimatedSeconds = estimatedSeconds
        self.statusRawValue = TaskStatus.notStarted.rawValue
        self.priorityRawValue = TaskPriority.normal.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
        self.subject = subject
        self.sessions = []
    }
}