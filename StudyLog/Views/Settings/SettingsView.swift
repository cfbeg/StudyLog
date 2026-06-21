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
            .navigationTitle("設定")
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
                Button("閉じる", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("すべてのデータを削除しますか？", isPresented: $isShowingDeleteAllConfirmation, titleVisibility: .visible) {
                Button("すべて削除", role: .destructive) {
                    deleteAllData()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべての教科、タスク、勉強記録が削除されます。この操作は元に戻せません。")
            }
        }
    }

    private func exportCSV() {
        do {
            exportFile = ExportFile(url: try ExportService.makeCSVFile(sessions: sessions))
        } catch {
            alertMessage = "CSVの作成に失敗しました: \(error.localizedDescription)"
        }
    }

    private func configureDailyReminder(enabled: Bool) {
        Task {
            do {
                if enabled {
                    guard try await NotificationService.requestAuthorization() else {
                        dailyReminderEnabled = false
                        alertMessage = "通知の許可が得られませんでした。"
                        return
                    }

                    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                    try await NotificationService.scheduleDailyReminder(hour: components.hour ?? 20, minute: components.minute ?? 0)
                } else {
                    NotificationService.cancelDailyReminder()
                }
            } catch {
                dailyReminderEnabled = false
                alertMessage = "通知設定に失敗しました: \(error.localizedDescription)"
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
                        alertMessage = "通知の許可が得られませんでした。"
                        return
                    }
                    try await NotificationService.rescheduleDueDateNotifications(for: currentTasks)
                } else {
                    await NotificationService.cancelDueDateNotifications()
                }
            } catch {
                dueDateReminderEnabled = false
                alertMessage = "期限通知の設定に失敗しました: \(error.localizedDescription)"
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
        Section("目標") {
            Stepper("1日の目標 \(dailyGoalMinutes)分", value: $dailyGoalMinutes, in: 0...720, step: 15)
            Toggle("週の開始を月曜日にする", isOn: $weekStartsOnMonday)
        }
    }
}

private struct SettingsNotificationsSection: View {
    @Binding var dailyReminderEnabled: Bool
    @Binding var dueDateReminderEnabled: Bool
    @Binding var reminderDate: Date

    var body: some View {
        Section {
            Toggle("毎日の勉強リマインダー", isOn: $dailyReminderEnabled)

            if dailyReminderEnabled {
                DatePicker("通知時刻", selection: $reminderDate, displayedComponents: .hourAndMinute)
            }

            Toggle("タスク期限通知", isOn: $dueDateReminderEnabled)
        } header: {
            Text("通知")
        } footer: {
            Text("通知はこの端末内だけでスケジュールされます。")
        }
    }
}

private struct SettingsDataSection: View {
    let canExportCSV: Bool
    let canDeleteAllData: Bool
    let exportCSV: () -> Void
    let showDeleteAllConfirmation: () -> Void

    var body: some View {
        Section("データ") {
            Button {
                exportCSV()
            } label: {
                Label("CSVを書き出す", systemImage: "square.and.arrow.up")
            }
            .disabled(!canExportCSV)

            Button(role: .destructive) {
                showDeleteAllConfirmation()
            } label: {
                Label("すべてのデータを削除", systemImage: "trash")
            }
            .disabled(!canDeleteAllData)
        }
    }
}

private struct SettingsThemeSection: View {
    @Binding var appTheme: String

    var body: some View {
        Section("テーマ") {
            Picker("アプリテーマ", selection: $appTheme) {
                Text("システム設定").tag("system")
                Text("ライト").tag("light")
                Text("ダーク").tag("dark")
            }
        }
    }
}

private struct SettingsAboutSection: View {
    var body: some View {
        Section("このアプリについて") {
            Text("教科を作り、タスクを追加し、タイマーで勉強時間を記録して、教科別・タスク別に振り返れます。")
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
