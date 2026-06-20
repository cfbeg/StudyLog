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
                        Text("謨咏ｧ・ \(subject.name)")
                            .foregroundStyle(.secondary)
                    }
                    Text("迥ｶ諷・ \(task.status.displayName)")
                    Text("蜆ｪ蜈亥ｺｦ: \(task.priority.displayName)")
                    if task.estimatedSeconds > 0 {
                        Text("莠亥ｮ壽凾髢・ \(DateUtils.formatDuration(task.estimatedSeconds))")
                    }
                    Text("螳溽ｸｾ譎る俣: \(DateUtils.formatDuration(task.spentSeconds))")
                    if let dueDate = task.dueDate {
                        Text("譛滄剞: \(DateUtils.dateFormatter.string(from: dueDate))")
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
                    Label("縺薙・繧ｿ繧ｹ繧ｯ縺ｧ蜍牙ｼｷ髢句ｧ・, systemImage: "play.circle.fill")
                }
                .disabled(task.subject == nil)

                Button {
                    toggleCompletion()
                } label: {
                    Label(task.status == .completed ? "譛ｪ螳御ｺ・↓謌ｻ縺・ : "螳御ｺ・↓縺吶ｋ", systemImage: task.status == .completed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                }
            }

            Section("螻･豁ｴ") {
                if sortedSessions.isEmpty {
                    Text("縺薙・繧ｿ繧ｹ繧ｯ縺ｮ險倬鹸縺ｯ縺ｾ縺縺ゅｊ縺ｾ縺帙ｓ縲・)
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
                    Label("蜑企勁", systemImage: "trash")
                }
            } footer: {
                Text("蜑企勁縺励※繧る℃蜴ｻ縺ｮ蜍牙ｼｷ繝ｭ繧ｰ縺ｯ谿九ｊ縲√ち繧ｹ繧ｯ縺ｨ縺ｮ邏舌▼縺代□縺大､悶ｌ縺ｾ縺吶・)
            }
        }
        .navigationTitle("繧ｿ繧ｹ繧ｯ隧ｳ邏ｰ")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("邱ｨ髮・) {
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
        .confirmationDialog("縺薙・繧ｿ繧ｹ繧ｯ繧貞炎髯､縺励∪縺吶°・・, isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("蜑企勁", role: .destructive) {
                deleteTask()
            }
            Button("繧ｭ繝｣繝ｳ繧ｻ繝ｫ", role: .cancel) {}
        }
    }

    private func toggleCompletion() {
        task.status = task.status == .completed ? .inProgress : .completed
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
