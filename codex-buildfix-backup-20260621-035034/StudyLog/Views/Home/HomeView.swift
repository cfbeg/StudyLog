import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]
    @Query(sort: \StudyTask.createdAt, order: .reverse) private var tasks: [StudyTask]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    @State private var isShowingTimer = false
    @State private var isShowingManualRecord = false

    private var activeSubjects: [Subject] {
        subjects.filter { !$0.isArchived }
    }

    private var todayTasks: [StudyTask] {
        tasks
            .filter { $0.status != .completed && $0.subject?.isArchived != true }
            .sorted {
                if $0.priority != $1.priority {
                    return priorityRank($0.priority) > priorityRank($1.priority)
                }
                return ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日の勉強")
                            .font(.headline)
                        Text(DateUtils.formatDuration(StatisticsService.totalSecondsToday(sessions: sessions)))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                    Button {
                        isShowingTimer = true
                    } label: {
                        Label("勉強開始", systemImage: "play.circle.fill")
                            .font(.headline)
                    }
                    .disabled(activeSubjects.isEmpty)

                    Button {
                        isShowingManualRecord = true
                    } label: {
                        Label("手動で記録", systemImage: "plus.circle")
                    }
                    .disabled(activeSubjects.isEmpty)
                }

                if activeSubjects.isEmpty {
                    EmptyStudyLogView {
                        addStarterSubjects()
                    }
                }

                Section("今日の教科別時間") {
                    ForEach(activeSubjects) { subject in
                        HStack {
                            Label(subject.name, systemImage: subject.iconName)
                                .foregroundStyle(ColorUtils.color(from: subject.colorHex))
                            Spacer()
                            Text(DateUtils.formatDuration(StatisticsService.totalSecondsToday(for: subject, sessions: sessions)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("今日やる予定のタスク") {
                    if todayTasks.isEmpty {
                        Text("未完了タスクはありません。いい風が吹いてます。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todayTasks.prefix(6)) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                TaskRow(task: task, showsSubject: true)
                            }
                        }
                    }
                }
            }
            .navigationTitle("StudyLog")
            .sheet(isPresented: $isShowingTimer) {
                StudyTimerView()
            }
            .sheet(isPresented: $isShowingManualRecord) {
                ManualRecordView()
            }
        }
    }

    private func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .low: 0
        case .normal: 1
        case .high: 2
        }
    }

    private func addStarterSubjects() {
        let samples = [
            ("数学", "#3B82F6", "function"),
            ("英語", "#EF4444", "text.book.closed.fill"),
            ("古典", "#8B5CF6", "scroll.fill")
        ]

        for (index, sample) in samples.enumerated() {
            modelContext.insert(Subject(name: sample.0, colorHex: sample.1, iconName: sample.2, displayOrder: index))
        }
    }
}

private struct EmptyStudyLogView: View {
    let addSamples: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("まずは教科を作りましょう")
                    .font(.headline)
                Text("数学・英語などを追加すると、タスクと勉強時間を記録できます。")
                    .foregroundStyle(.secondary)
                Button("サンプル教科を追加", action: addSamples)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }
}
