import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var dailyGoalSeconds: Int
    var weeklyGoalSeconds: Int
    var displayOrder: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var tasks: [StudyTask]

    @Relationship(deleteRule: .cascade)
    var sessions: [StudySession]

    init(
        name: String,
        colorHex: String,
        iconName: String,
        dailyGoalSeconds: Int = 0,
        weeklyGoalSeconds: Int = 0,
        displayOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.dailyGoalSeconds = dailyGoalSeconds
        self.weeklyGoalSeconds = weeklyGoalSeconds
        self.displayOrder = displayOrder
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tasks = []
        self.sessions = []
    }
}
