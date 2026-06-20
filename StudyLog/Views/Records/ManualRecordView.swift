import SwiftData
import SwiftUI

struct ManualRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]

    @State private var selectedSubjectID: UUID?
    @State private var selectedTaskID: UUID?
    @State private var startedAt = Date()
    @State private var durationMinutes = 30
    @State private var memo = ""

    private var activeSubjects: [Subject] {
        subjects.filter { !$0.isArchived }
    }

    private var selectedSubject: Subject? {
        activeSubjects.first { $0.id == selectedSubjectID }
    }

    private var selectedTask: StudyTask? {
        availableTasks.first { $0.id == selectedTaskID }
    }

    private var availableTasks: [StudyTask] {
        (selectedSubject?.tasks ?? [])
            .filter { $0.status != .completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("記録") {
                    Picker("教科", selection: $selectedSubjectID) {
                        Text("選択してください").tag(UUID?.none)
                        ForEach(activeSubjects) { subject in
                            Text(subject.name).tag(UUID?.some(subject.id))
                        }
                    }

                    Picker("タスク", selection: $selectedTaskID) {
                        Text("なし").tag(UUID?.none)
                        ForEach(availableTasks) { task in
                            Text(task.title).tag(UUID?.some(task.id))
                        }
                    }
                    .disabled(selectedSubjectID == nil)

                    DatePicker("開始", selection: $startedAt)
                    Stepper("時間 (durationMinutes) 分", value: $durationMinutes, in: 1...720, step: 5)
                    TextField("メモ", text: $memo, axis: .vertical)
                }
            }
            .navigationTitle("手動記録")
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
                    .disabled(selectedSubjectID == nil)
                }
            }
            .onChange(of: selectedSubjectID) {
                selectedTaskID = nil
            }
            .onAppear {
                selectedSubjectID = selectedSubjectID ?? activeSubjects.first?.id
            }
        }
    }

    private func save() {
        guard let selectedSubject else { return }
        let endedAt = startedAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let session = StudySession(subject: selectedSubject, task: selectedTask, startedAt: startedAt, endedAt: endedAt, memo: memo, isManual: true)
        modelContext.insert(session)
        selectedTask?.status = .inProgress
        dismiss()
    }
}
