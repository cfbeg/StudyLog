import SwiftData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let subject: Subject
    private let task: StudyTask?

    @State private var title: String
    @State private var note: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var estimatedMinutes: Int
    @State private var status: TaskStatus
    @State private var priority: TaskPriority

    init(subject: Subject, task: StudyTask? = nil) {
        self.subject = subject
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _note = State(initialValue: task?.note ?? "")
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? Date())
        _estimatedMinutes = State(initialValue: (task?.estimatedSeconds ?? 0) / 60)
        _status = State(initialValue: task?.status ?? .notStarted)
        _priority = State(initialValue: task?.priority ?? .normal)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("タスク名", text: $title)
                    TextField("メモ", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("予定") {
                    Stepper("予定 (estimatedMinutes) 分", value: $estimatedMinutes, in: 0...600, step: 5)
                    Toggle("期限を設定", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("期限", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("状態") {
                    Picker("状態", selection: $status) {
                        ForEach(TaskStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }

                    Picker("優先度", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "タスクを追加" : "タスクを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let task {
            task.title = trimmedTitle
            task.note = note
            task.dueDate = hasDueDate ? dueDate : nil
            task.estimatedSeconds = estimatedMinutes * 60
            task.status = status
            task.priority = priority
            task.updatedAt = Date()
        } else {
            let newTask = StudyTask(title: trimmedTitle, subject: subject, estimatedSeconds: estimatedMinutes * 60)
            newTask.note = note
            newTask.dueDate = hasDueDate ? dueDate : nil
            newTask.status = status
            newTask.priority = priority
            modelContext.insert(newTask)
        }

        dismiss()
    }
}
