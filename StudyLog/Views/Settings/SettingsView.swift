import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]
    @Query(sort: \StudyTask.createdAt, order: .reverse) private var tasks: [StudyTask]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 120
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = true
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("dueDateReminderEnabled") private var dueDateReminderEnabled = false

    @State private var reminderDate = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var exportFile: ExportFile?
    @State private var alertMessage: String?
    @State private var isShowingDeleteAllConfirmation = false

    private var canExportCSV: Bool {
        !sessions.isEmpty
    }

    private var canDeleteAllData: Bool {
        !(subjects.isEmpty && tasks.isEmpty && sessions.isEmpty)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            SettingsForm(
                dailyGoalMinutes: $dailyGoalMinutes,
                weekStartsOnMonday: $weekStartsOnMonday,
                appTheme: $appTheme,
                dailyReminderEnabled: $dailyReminderEnabled,
                dueDateReminderEnabled: $dueDateReminderEnabled,
                reminderDate: $reminderDate,
                canExportCSV: canExportCSV,
                canDeleteAllData: canDeleteAllData,
                exportCSV: exportCSV,
                showDeleteAllConfirmation: {
                    isShowingDeleteAllConfirmation = true
                }
            )
            .navigationTitle("Settings")
            .onChange(of: dailyReminderEnabled) { _, enabled in
                configureDailyReminder(enabled: enabled)
            }
            .onChange(of: reminderDate) { _, _ in
                if dailyReminderEnabled {
                    configureDailyReminder(enabled: true)
                }
            }
            .onChange(of: dueDateReminderEnabled) { _, enabled in
                configureDueDateReminders(enabled: enabled)
            }
            .sheet(item: $exportFile) { exportFile in
                ShareSheet(activityItems: [exportFile.url])
            }
            .alert("StudyLog", isPresented: alertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("Delete all data?", isPresented: $isShowingDeleteAllConfirmation, titleVisibility: .visible) {
                Button("Delete all data", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all subjects, tasks, and study sessions. This cannot be undone.")
            }
        }
    }

    private func exportCSV() {
        do {
            exportFile = ExportFile(url: try ExportService.makeCSVFile(sessions: sessions))
        } catch {
            alertMessage = "Failed to create CSV: \(error.localizedDescription)"
        }
    }

    private func configureDailyReminder(enabled: Bool) {
        Task {
            do {
                if enabled {
                    guard try await NotificationService.requestAuthorization() else {
                        dailyReminderEnabled = false
                        alertMessage = "Notification permission was not granted."
                        return
                    }

                    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                    try await NotificationService.scheduleDailyReminder(hour: components.hour ?? 20, minute: components.minute ?? 0)
                } else {
                    NotificationService.cancelDailyReminder()
                }
            } catch {
                dailyReminderEnabled = false
                alertMessage = "Failed to configure notification: \(error.localizedDescription)"
            }
        }
    }

    private func configureDueDateReminders(enabled: Bool) {
        let currentTasks = tasks

        Task {
            do {
                if enabled {
                    guard try await NotificationService.requestAuthorization() else {
                        dueDateReminderEnabled = false
                        alertMessage = "Notification permission was not granted."
                        return
                    }
                    try await NotificationService.rescheduleDueDateNotifications(for: currentTasks)
                } else {
                    await NotificationService.cancelDueDateNotifications()
                }
            } catch {
                dueDateReminderEnabled = false
                alertMessage = "Failed to configure due-date reminders: \(error.localizedDescription)"
            }
        }
    }

    private func deleteAllData() {
        for session in sessions {
            modelContext.delete(session)
        }
        for task in tasks {
            modelContext.delete(task)
        }
        for subject in subjects {
            modelContext.delete(subject)
        }
        try? modelContext.save()
    }
}

private struct SettingsForm: View {
    @Binding var dailyGoalMinutes: Int
    @Binding var weekStartsOnMonday: Bool
    @Binding var appTheme: String
    @Binding var dailyReminderEnabled: Bool
    @Binding var dueDateReminderEnabled: Bool
    @Binding var reminderDate: Date

    let canExportCSV: Bool
    let canDeleteAllData: Bool
    let exportCSV: () -> Void
    let showDeleteAllConfirmation: () -> Void

    var body: some View {
        Form {
            SettingsGoalsSection(
                dailyGoalMinutes: $dailyGoalMinutes,
                weekStartsOnMonday: $weekStartsOnMonday
            )

            SettingsNotificationsSection(
                dailyReminderEnabled: $dailyReminderEnabled,
                dueDateReminderEnabled: $dueDateReminderEnabled,
                reminderDate: $reminderDate
            )

            SettingsDataSection(
                canExportCSV: canExportCSV,
                canDeleteAllData: canDeleteAllData,
                exportCSV: exportCSV,
                showDeleteAllConfirmation: showDeleteAllConfirmation
            )

            SettingsThemeSection(appTheme: $appTheme)
            SettingsAboutSection()
        }
    }
}

private struct SettingsGoalsSection: View {
    @Binding var dailyGoalMinutes: Int
    @Binding var weekStartsOnMonday: Bool

    var body: some View {
        Section("Goals") {
            Stepper("Daily goal \(dailyGoalMinutes) min", value: $dailyGoalMinutes, in: 0...720, step: 15)
            Toggle("Week starts on Monday", isOn: $weekStartsOnMonday)
        }
    }
}

private struct SettingsNotificationsSection: View {
    @Binding var dailyReminderEnabled: Bool
    @Binding var dueDateReminderEnabled: Bool
    @Binding var reminderDate: Date

    var body: some View {
        Section {
            Toggle("Daily study reminder", isOn: $dailyReminderEnabled)

            if dailyReminderEnabled {
                DatePicker("Reminder time", selection: $reminderDate, displayedComponents: .hourAndMinute)
            }

            Toggle("Task due-date reminders", isOn: $dueDateReminderEnabled)
        } header: {
            Text("Notifications")
        } footer: {
            Text("Notifications are scheduled locally on this device.")
        }
    }
}

private struct SettingsDataSection: View {
    let canExportCSV: Bool
    let canDeleteAllData: Bool
    let exportCSV: () -> Void
    let showDeleteAllConfirmation: () -> Void

    var body: some View {
        Section("Data") {
            Button {
                exportCSV()
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(!canExportCSV)

            Button(role: .destructive) {
                showDeleteAllConfirmation()
            } label: {
                Label("Delete all data", systemImage: "trash")
            }
            .disabled(!canDeleteAllData)
        }
    }
}

private struct SettingsThemeSection: View {
    @Binding var appTheme: String

    var body: some View {
        Section("Theme") {
            Picker("App theme", selection: $appTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        }
    }
}

private struct SettingsAboutSection: View {
    var body: some View {
        Section("About") {
            Text("Create subjects, add tasks, start a timer, and review study time by subject and task.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
