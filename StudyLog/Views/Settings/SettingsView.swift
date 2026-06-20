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

    var body: some View {
        NavigationStack {
            Form {
                Section("逶ｮ讓・) {
                    Stepper("1譌･縺ｮ逶ｮ讓・\(dailyGoalMinutes) 蛻・, value: $dailyGoalMinutes, in: 0...720, step: 15)
                    Toggle("騾ｱ縺ｮ髢句ｧ九ｒ譛域屆譌･縺ｫ縺吶ｋ", isOn: $weekStartsOnMonday)
                }

                Section("騾夂衍") {
                    Toggle("豈取律縺ｮ險倬鹸繝ｪ繝槭う繝ｳ繝繝ｼ", isOn: $dailyReminderEnabled)
                    if dailyReminderEnabled {
                        DatePicker("騾夂衍譎ょ綾", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    }

                    Toggle("繧ｿ繧ｹ繧ｯ譛滄剞蜑肴律縺ｮ騾夂衍", isOn: $dueDateReminderEnabled)
                } footer: {
                    Text("騾夂衍縺ｯ遶ｯ譛ｫ蜀・□縺代〒邂｡逅・＠縺ｾ縺吶ょ・蝗槭が繝ｳ譎ゅ↓騾夂衍險ｱ蜿ｯ繧呈ｱゅａ縺ｾ縺吶・)
                }

                Section("繝・・繧ｿ") {
                    Button {
                        exportCSV()
                    } label: {
                        Label("CSV 繧ｨ繧ｯ繧ｹ繝昴・繝・, systemImage: "square.and.arrow.up")
                    }
                    .disabled(sessions.isEmpty)

                    Button(role: .destructive) {
                        isShowingDeleteAllConfirmation = true
                    } label: {
                        Label("繝・・繧ｿ蜈ｨ蜑企勁", systemImage: "trash")
                    }
                    .disabled(subjects.isEmpty && tasks.isEmpty && sessions.isEmpty)
                }

                Section("繝・・繝・) {
                    Picker("繧｢繝励Μ繝・・繝・, selection: $appTheme) {
                        Text("繧ｷ繧ｹ繝・Β").tag("system")
                        Text("繝ｩ繧､繝・).tag("light")
                        Text("繝繝ｼ繧ｯ").tag("dark")
                    }
                }

                Section("縺薙・繧｢繝励Μ") {
                    Text("謨咏ｧ代ｒ菴懊ｋ 竊・繧ｿ繧ｹ繧ｯ繧剃ｽ懊ｋ 竊・繧ｿ繧ｹ繧ｯ繧帝∈繧薙〒繧ｿ繧､繝槭・髢句ｧ九√→縺・≧霆ｽ縺・ｵ√ｌ繧剃ｸｭ蠢・↓縺励◆繧ｪ繝輔Λ繧､繝ｳ蟄ｦ鄙偵Ο繧ｰ縺ｧ縺吶・)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("險ｭ螳・)
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
            .alert("StudyLog", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("縺吶∋縺ｦ縺ｮ繝・・繧ｿ繧貞炎髯､縺励∪縺吶°・・, isPresented: $isShowingDeleteAllConfirmation, titleVisibility: .visible) {
                Button("縺吶∋縺ｦ蜑企勁", role: .destructive) {
                    deleteAllData()
                }
                Button("繧ｭ繝｣繝ｳ繧ｻ繝ｫ", role: .cancel) {}
            } message: {
                Text("謨咏ｧ代・繧ｿ繧ｹ繧ｯ繝ｻ蜍牙ｼｷ繝ｭ繧ｰ繧偵☆縺ｹ縺ｦ蜑企勁縺励∪縺吶ゅ％縺ｮ謫堺ｽ懊・蜈・↓謌ｻ縺帙∪縺帙ｓ縲・)
            }
        }
    }

    private func exportCSV() {
        do {
            exportFile = ExportFile(url: try ExportService.makeCSVFile(sessions: sessions))
        } catch {
            alertMessage = "CSV 縺ｮ菴懈・縺ｫ螟ｱ謨励＠縺ｾ縺励◆: \(error.localizedDescription)"
        }
    }

    private func configureDailyReminder(enabled: Bool) {
        Swift.Task {
            do {
                if enabled {
                    guard try await NotificationService.requestAuthorization() else {
                        dailyReminderEnabled = false
                        alertMessage = "騾夂衍縺瑚ｨｱ蜿ｯ縺輔ｌ縺ｾ縺帙ｓ縺ｧ縺励◆縲・
                        return
                    }

                    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                    try await NotificationService.scheduleDailyReminder(hour: components.hour ?? 20, minute: components.minute ?? 0)
                } else {
                    NotificationService.cancelDailyReminder()
                }
            } catch {
                dailyReminderEnabled = false
                alertMessage = "騾夂衍險ｭ螳壹↓螟ｱ謨励＠縺ｾ縺励◆: \(error.localizedDescription)"
            }
        }
    }

    private func configureDueDateReminders(enabled: Bool) {
        Swift.Task {
            do {
                if enabled {
                    guard try await NotificationService.requestAuthorization() else {
                        dueDateReminderEnabled = false
                        alertMessage = "騾夂衍縺瑚ｨｱ蜿ｯ縺輔ｌ縺ｾ縺帙ｓ縺ｧ縺励◆縲・
                        return
                    }
                    try await NotificationService.rescheduleDueDateNotifications(for: tasks)
                } else {
                    await NotificationService.cancelDueDateNotifications()
                }
            } catch {
                dueDateReminderEnabled = false
                alertMessage = "譛滄剞騾夂衍縺ｮ險ｭ螳壹↓螟ｱ謨励＠縺ｾ縺励◆: \(error.localizedDescription)"
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
