import SwiftData
import SwiftUI

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var subject: Subject
    @Query(sort: \StudySession.startedAt, order: .reverse) private var allSessions: [StudySession]

    @State private var isShowingTaskEditor = false
    @State private var isShowingTimer = false
    @State private var isShowingSubjectEditor = false

    private var subjectSessions: [StudySession] {
        allSessions.filter { $0.subject?.id == subject.id }
    }

    private var pendingTasks: [StudyTask] {
        subject.tasks
            .filter { $0.status != .completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var completedTasks: [StudyTask] {
        subject.tasks
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(subject.name, systemImage: subject.iconName)
                        .font(.title2.bold())
                        .foregroundStyle(ColorUtils.color(from: subject.colorHex))

                    HStack {
                        MetricPill(title: "今日", seconds: StatisticsService.totalSecondsToday(for: subject, sessions: allSessions))
                        MetricPill(title: "今週", seconds: StatisticsService.totalSecondsThisWeek(for: subject, sessions: allSessions))
                        MetricPill(title: "累計", seconds: StatisticsService.totalSeconds(for: subject, sessions: allSessions))
                    }
                }
                .padding(.vertical, 6)

                Button {
                    isShowingTimer = true
                } label: {
                    Label("この教科で勉強開始", systemImage: "play.circle.fill")
                }

                Button {
                    isShowingTaskEditor = true
                } label: {
                    Label("タスクを追加", systemImage: "checklist")
                }
            }

            Section("未完了タスク") {
                if pendingTasks.isEmpty {
                    Text("未完了タスクはありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pendingTasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRow(task: task, showsSubject: false)
                        }
                    }
                }
            }

            Section("完了済み") {
                if completedTasks.isEmpty {
                    Text("まだ完了済みタスクはありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(completedTasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRow(task: task, showsSubject: false)
                        }
                    }
                }
            }

            Section("勉強履歴") {
                if subjectSessions.isEmpty {
                    Text("この教科の記録はまだありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(subjectSessions.prefix(10)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle(subject.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    isShowingSubjectEditor = true
                }
            }
        }
        .sheet(isPresented: $isShowingTaskEditor) {
            TaskEditorView(subject: subject)
        }
        .sheet(isPresented: $isShowingTimer) {
            StudyTimerView(initialSubject: subject)
        }
        .sheet(isPresented: $isShowingSubjectEditor) {
            SubjectEditorView(subject: subject)
        }
    }
}

struct MetricPill: View {
    let title: String
    let seconds: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(DateUtils.formatDuration(seconds))
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
