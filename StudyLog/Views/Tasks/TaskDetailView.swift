import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: StudyTask

    @State private var isShowingEditor = false
    @State private var isShowingTimer = false
    @State private var isShowingDeleteConfirmation = false

    private var sortedSessions: [StudySession] {
        task.sessions.sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2.bold())
                    if let subject = task.subject {
                        Text("教科: \(subject.name)")
                            .foregroundStyle(.secondary)
                    }
                    Text("状態: \(task.status.displayName)")
                    Text("優先度: \(task.priority.displayName)")
                    if task.estimatedSeconds > 0 {
                        Text("予定時間: \(DateUtils.formatDuration(task.estimatedSeconds))")
                    }
                    Text("実績時間: \(DateUtils.formatDuration(task.spentSeconds))")
                    if let dueDate = task.dueDate {
                        Text("期限: \(DateUtils.dateFormatter.string(from: dueDate))")
                    }
                    if !task.note.isEmpty {
                        Text(task.note)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 6)

                Button {
                    isShowingTimer = true
                } label: {
                    Label("このタスクで勉強開始", systemImage: "play.circle.fill")
                }
                .disabled(task.subject == nil)

                Button {
                    toggleCompletion()
                } label: {
                    Label(task.status == .completed ? "未完了に戻す" : "完了にする", systemImage: task.status == .completed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                }
            }

            Section("履歴") {
                if sortedSessions.isEmpty {
                    Text("このタスクの勉強記録はまだありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSessions) { session in
                        SessionRow(session: session)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            } footer: {
                Text("タスクを削除しても過去の勉強記録は残りますが、タスクとの紐づけは外れます。")
            }
        }
        .navigationTitle("タスク詳細")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    isShowingEditor = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            if let subject = task.subject {
                TaskEditorView(subject: subject, task: task)
            }
        }
        .sheet(isPresented: $isShowingTimer) {
            if let subject = task.subject {
                StudyTimerView(initialSubject: subject, initialTask: task)
            }
        }
        .confirmationDialog("このタスクを削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                deleteTask()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func toggleCompletion() {
        task.status = task.status == .completed ? .inProgress : .completed
        try? modelContext.save()
    }

    private func deleteTask() {
        for session in task.sessions {
            session.task = nil
        }
        modelContext.delete(task)
        try? modelContext.save()
        dismiss()
    }
}