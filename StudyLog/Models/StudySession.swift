import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: Int
    var memo: String
    var isManual: Bool
    var createdAt: Date
    var updatedAt: Date

    var subject: Subject?
    var task: StudyTask?

    init(
        subject: Subject,
        task: StudyTask? = nil,
        startedAt: Date,
        endedAt: Date,
        memo: String = "",
        isManual: Bool = false
    ) {
        self.id = UUID()
        self.subject = subject
        self.task = task
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = max(0, Int(endedAt.timeIntervalSince(startedAt)))
        self.memo = memo
        self.isManual = isManual
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
