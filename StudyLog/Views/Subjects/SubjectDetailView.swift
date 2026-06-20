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
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(subject.name, systemImage: subject.iconName)
                        .font(.title2.bold())
                        .foregroundStyle(ColorUtils.color(from: subject.colorHex))

                    HStack {
                        MetricPill(title: "莉頑律", seconds: StatisticsService.totalSecondsToday(for: subject, sessions: allSessions))
                        MetricPill(title: "莉企ｱ", seconds: StatisticsService.totalSecondsThisWeek(for: subject, sessions: allSessions))
                        MetricPill(title: "邏ｯ險・, seconds: StatisticsService.totalSeconds(for: subject, sessions: allSessions))
                    }

                    if subject.dailyGoalSeconds > 0 {
                        ProgressView(
                            value: StatisticsService.progressRatio(
                                seconds: StatisticsService.totalSecondsToday(for: subject, sessions: allSessions),
                                goalSeconds: subject.dailyGoalSeconds
                            )
                        ) {
                            Text("莉頑律縺ｮ逶ｮ讓・\(DateUtils.formatDuration(subject.dailyGoalSeconds))")
                        }
                        .tint(ColorUtils.color(from: subject.colorHex))
                    }
                }
                .padding(.vertical, 6)

                Button {
                    isShowingTimer = true
                } label: {
                    Label("縺薙・謨咏ｧ代〒蜍牙ｼｷ髢句ｧ・, systemImage: "play.circle.fill")
                }

                Button {
                    isShowingTaskEditor = true
                } label: {
                    Label("繧ｿ繧ｹ繧ｯ繧定ｿｽ蜉", systemImage: "checklist")
                }
            }

            Section("譛ｪ螳御ｺ・ち繧ｹ繧ｯ") {
                if pendingTasks.isEmpty {
                    Text("譛ｪ螳御ｺ・ち繧ｹ繧ｯ縺ｯ縺ゅｊ縺ｾ縺帙ｓ縲・)
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

            Section {
                Button {
                    withAnimation {
                        isShowingCompletedTasks.toggle()
                    }
                } label: {
                    Label(
                        isShowingCompletedTasks ? "螳御ｺ・ｸ医∩繧帝國縺・ : "螳御ｺ・ｸ医∩繧定｡ｨ遉ｺ・・(completedTasks.count)・・,
                        systemImage: isShowingCompletedTasks ? "chevron.up.circle" : "chevron.down.circle"
                    )
                }

                if isShowingCompletedTasks {
                    if completedTasks.isEmpty {
                        Text("縺ｾ縺螳御ｺ・ｸ医∩繧ｿ繧ｹ繧ｯ縺ｯ縺ゅｊ縺ｾ縺帙ｓ縲・)
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
            } header: {
                Text("螳御ｺ・ｸ医∩")
            }

            Section("蜍牙ｼｷ螻･豁ｴ") {
                if subjectSessions.isEmpty {
                    Text("縺薙・謨咏ｧ代・險倬鹸縺ｯ縺ｾ縺縺ゅｊ縺ｾ縺帙ｓ縲・)
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
                Menu {
                    Button("邱ｨ髮・, systemImage: "pencil") {
                        isShowingSubjectEditor = true
                    }

                    Button("繧｢繝ｼ繧ｫ繧､繝・, systemImage: "archivebox") {
                        subject.isArchived = true
                        subject.updatedAt = Date()
                        dismiss()
                    }

                    Button("螳悟・縺ｫ蜑企勁", systemImage: "trash", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
        .confirmationDialog("縺薙・謨咏ｧ代ｒ螳悟・縺ｫ蜑企勁縺励∪縺吶°・・, isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("螳悟・縺ｫ蜑企勁", role: .destructive) {
                permanentlyDeleteSubject()
            }
            Button("繧ｭ繝｣繝ｳ繧ｻ繝ｫ", role: .cancel) {}
        } message: {
            Text("驕主悉縺ｮ蜍牙ｼｷ繝ｭ繧ｰ縺ｯ谿九＠縲∵蕗遘代→繧ｿ繧ｹ繧ｯ縺ｮ邏舌▼縺代□縺大､悶＠縺ｾ縺吶・)
        }
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
