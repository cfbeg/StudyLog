import SwiftData
import SwiftUI

struct StudyTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]

    @State private var engine = TimerEngine()
    @State private var selectedSubjectID: UUID?
    @State private var selectedTaskID: UUID?
    @State private var memo = ""
    @State private var displaySeconds = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let initialSubject: Subject?
    private let initialTask: StudyTask?

    init(initialSubject: Subject? = nil, initialTask: StudyTask? = nil) {
        self.initialSubject = initialSubject
        self.initialTask = initialTask
    }

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
            VStack(spacing: 24) {
                Form {
                    Section("対象") {
                        Picker("教科", selection: $selectedSubjectID) {
                            Text("選択してください").tag(UUID?.none)
                            ForEach(activeSubjects) { subject in
                                Text(subject.name).tag(UUID?.some(subject.id))
                            }
                        }
                        .disabled(engine.isRunning)

                        Picker("タスク", selection: $selectedTaskID) {
                            Text("なし").tag(UUID?.none)
                            ForEach(availableTasks) { task in
                                Text(task.title).tag(UUID?.some(task.id))
                            }
                        }
                        .disabled(selectedSubjectID == nil || engine.isRunning)

                        TextField("メモ", text: $memo, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                .frame(maxHeight: 260)

                Text(DateUtils.formatDuration(displaySeconds))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 16) {
                    if !engine.isRunning {
                        Button {
                            engine.start()
                            displaySeconds = 0
                        } label: {
                            Label("開始", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedSubjectID == nil)
                    } else {
                        Button {
                            if engine.isPaused {
                                engine.resume()
                            } else {
                                engine.pause()
                            }
                        } label: {
                            Label(engine.isPaused ? "再開" : "一時停止", systemImage: engine.isPaused ? "play.fill" : "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            saveAndStop()
                        } label: {
                            Label("終了して保存", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("勉強タイマー")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .disabled(engine.isRunning)
                }
            }
            .onReceive(timer) { _ in
                displaySeconds = engine.elapsedSeconds()
            }
            .onAppear {
                selectedSubjectID = initialSubject?.id ?? selectedSubjectID ?? activeSubjects.first?.id
                selectedTaskID = initialTask?.id
            }
            .onChange(of: selectedSubjectID) {
                if selectedSubjectID != selectedTask?.subject?.id {
                    selectedTaskID = nil
                }
            }
        }
    }

    private func saveAndStop() {
        guard let selectedSubject else { return }
        let seconds = engine.stop()
        let endedAt = Date()
        let startedAt = endedAt.addingTimeInterval(TimeInterval(-seconds))
        let session = StudySession(subject: selectedSubject, task: selectedTask, startedAt: startedAt, endedAt: endedAt, memo: memo, isManual: false)
        modelContext.insert(session)
        selectedTask?.status = .inProgress
        dismiss()
    }
}
