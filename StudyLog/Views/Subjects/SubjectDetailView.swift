import SwiftData
import SwiftUI

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var subject: Subject
    @Query(sort: \StudySession.startedAt, order: .reverse) private var allSessions: [StudySession]

    @State private var isShowingTaskEditor = false
    @State private var isShowingTimer = false
    @State private var isShowingSubjectEditor = false
    @State private var isShowingCompletedTasks = false
    @State private var isShowingDeleteConfirmation = false

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
            SubjectOverviewSection(
                subject: subject,
                allSessions: allSessions,
                startStudy: { isShowingTimer = true },
                addTask: { isShowingTaskEditor = true }
            )

            SubjectOpenTasksSection(tasks: pendingTasks)

            SubjectCompletedTasksSection(
                tasks: completedTasks,
                isShowingCompletedTasks: $isShowingCompletedTasks
            )

            SubjectHistorySection(sessions: Array(subjectSessions.prefix(10)))
        }
        .navigationTitle(subject.name)
        .toolbar {
            SubjectDetailToolbar(
                edit: { isShowingSubjectEditor = true },
                archive: archiveSubject,
                requestDelete: { isShowingDeleteConfirmation = true }
            )
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
        .confirmationDialog("Delete this subject?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) {
                permanentlyDeleteSubject()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Past study sessions will remain, but subject and task links will be removed.")
        }
    }

    private func archiveSubject() {
        subject.isArchived = true
        subject.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }

    private func permanentlyDeleteSubject() {
        let subjectTasks = Array(subject.tasks)
        let subjectSessions = Array(subject.sessions)

        for task in subjectTasks {
            for session in task.sessions {
                session.task = nil
            }
            modelContext.delete(task)
        }

        for session in subjectSessions {
            session.subject = nil
        }

        modelContext.delete(subject)
        try? modelContext.save()
        dismiss()
    }
}

private struct SubjectOverviewSection: View {
    let subject: Subject
    let allSessions: [StudySession]
    let startStudy: () -> Void
    let addTask: () -> Void

    private var todaySeconds: Int {
        StatisticsService.totalSecondsToday(for: subject, sessions: allSessions)
    }

    private var weekSeconds: Int {
        StatisticsService.totalSecondsThisWeek(for: subject, sessions: allSessions)
    }

    private var totalSeconds: Int {
        StatisticsService.totalSeconds(for: subject, sessions: allSessions)
    }

    private var subjectColor: Color {
        ColorUtils.color(from: subject.colorHex)
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label(subject.name, systemImage: subject.iconName)
                    .font(.title2.bold())
                    .foregroundStyle(subjectColor)

                HStack {
                    MetricPill(title: "Today", seconds: todaySeconds)
                    MetricPill(title: "Week", seconds: weekSeconds)
                    MetricPill(title: "Total", seconds: totalSeconds)
                }

                if subject.dailyGoalSeconds > 0 {
                    ProgressView(
                        value: StatisticsService.progressRatio(
                            seconds: todaySeconds,
                            goalSeconds: subject.dailyGoalSeconds
                        )
                    ) {
                        Text("Daily goal \(DateUtils.formatDuration(subject.dailyGoalSeconds))")
                    }
                    .tint(subjectColor)
                }
            }
            .padding(.vertical, 6)

            Button {
                startStudy()
            } label: {
                Label("Start studying this subject", systemImage: "play.circle.fill")
            }

            Button {
                addTask()
            } label: {
                Label("Add task", systemImage: "checklist")
            }
        }
    }
}

private struct SubjectOpenTasksSection: View {
    let tasks: [StudyTask]

    var body: some View {
        Section("Open tasks") {
            if tasks.isEmpty {
                Text("No open tasks.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task)
                    } label: {
                        TaskRow(task: task, showsSubject: false)
                    }
                }
            }
        }
    }
}

private struct SubjectCompletedTasksSection: View {
    let tasks: [StudyTask]
    @Binding var isShowingCompletedTasks: Bool

    var body: some View {
        Section {
            Button {
                withAnimation {
                    isShowingCompletedTasks.toggle()
                }
            } label: {
                Label(
                    isShowingCompletedTasks ? "Hide completed" : "Show completed (\(tasks.count))",
                    systemImage: isShowingCompletedTasks ? "chevron.up.circle" : "chevron.down.circle"
                )
            }

            if isShowingCompletedTasks {
                CompletedTaskList(tasks: tasks)
            }
        } header: {
            Text("Completed")
        }
    }
}

private struct CompletedTaskList: View {
    let tasks: [StudyTask]

    var body: some View {
        if tasks.isEmpty {
            Text("No completed tasks yet.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(tasks) { task in
                NavigationLink {
                    TaskDetailView(task: task)
                } label: {
                    TaskRow(task: task, showsSubject: false)
                }
            }
        }
    }
}

private struct SubjectHistorySection: View {
    let sessions: [StudySession]

    var body: some View {
        Section("Study history") {
            if sessions.isEmpty {
                Text("No sessions for this subject yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

private struct SubjectDetailToolbar: ToolbarContent {
    let edit: () -> Void
    let archive: () -> Void
    let requestDelete: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Edit", systemImage: "pencil") {
                    edit()
                }

                Button("Archive", systemImage: "archivebox") {
                    archive()
                }

                Button("Delete permanently", systemImage: "trash", role: .destructive) {
                    requestDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
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
