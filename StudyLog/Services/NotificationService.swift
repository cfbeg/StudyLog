import Foundation
import UserNotifications

enum NotificationService {
    static let minimumSupportedFeatures = [
        "Daily study reminder",
        "Task due-date reminder",
        "Timer finish notification"
    ]

    static func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "今日の勉強を記録しよう"
        content.body = "短い勉強でも、StudyLogに残しておく価値があります。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-study-reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        try await UNUserNotificationCenter.current().add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-study-reminder"])
    }

    static func rescheduleDueDateNotifications(for tasks: [StudyTask]) async throws {
        let center = UNUserNotificationCenter.current()
        let oldIdentifiers = await pendingNotificationIdentifiers(prefix: "task-due-")
        center.removePendingNotificationRequests(withIdentifiers: oldIdentifiers)

        for task in tasks where task.status != .completed {
            guard let dueDate = task.dueDate,
                  let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate),
                  notificationDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "明日が期限のタスクがあります"
            content.body = task.subject.map { "\($0.name): \(task.title)" } ?? task.title
            content.sound = .default

            var components = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
            components.hour = 19
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "task-due-\(task.id.uuidString)", content: content, trigger: trigger)
            try await center.add(request)
        }
    }

    static func cancelDueDateNotifications() async {
        let identifiers = await pendingNotificationIdentifiers(prefix: "task-due-")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func pendingNotificationIdentifiers(prefix: String) async -> [String] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests.map(\.identifier).filter { $0.hasPrefix(prefix) })
            }
        }
    }
}