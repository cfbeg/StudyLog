import SwiftData
import SwiftUI

struct SubjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var isShowingEditor = false
    @State private var subjectPendingDeletion: Subject?

    private var activeSubjects: [Subject] {
        subjects.filter { !$0.isArchived }
    }

    private var archivedSubjects: [Subject] {
        subjects.filter(\.isArchived)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(activeSubjects) { subject in
                        NavigationLink {
                            SubjectDetailView(subject: subject)
                        } label: {
                            SubjectSummaryRow(subject: subject, sessions: sessions)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                subjectPendingDeletion = subject
                            } label: {
                                Label("蜑企勁", systemImage: "trash")
                            }

                            Button {
                                archive(subject)
                            } label: {
                                Label("繧｢繝ｼ繧ｫ繧､繝・, systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                    }
                    .onMove(perform: moveSubjects)
                } header: {
                    Text("陦ｨ遉ｺ荳ｭ")
                } footer: {
                    Text("荳ｦ縺ｳ譖ｿ縺医・蜿ｳ荳翫・邱ｨ髮・°繧峨〒縺阪∪縺吶ょ炎髯､縺励※繧る℃蜴ｻ縺ｮ蜍牙ｼｷ繝ｭ繧ｰ縺ｯ谿九＠縺ｾ縺吶・)
                }

                if !archivedSubjects.isEmpty {
                    Section("繧｢繝ｼ繧ｫ繧､繝・) {
                        ForEach(archivedSubjects) { subject in
                            SubjectSummaryRow(subject: subject, sessions: sessions)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        subjectPendingDeletion = subject
                                    } label: {
                                        Label("蜑企勁", systemImage: "trash")
                                    }

                                    Button {
                                        restore(subject)
                                    } label: {
                                        Label("謌ｻ縺・, systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }

                if activeSubjects.isEmpty {
                    ContentUnavailableView("謨咏ｧ代′縺ゅｊ縺ｾ縺帙ｓ", systemImage: "books.vertical", description: Text("蜿ｳ荳翫・霑ｽ蜉繝懊ち繝ｳ縺九ｉ謨咏ｧ代ｒ菴懈・縺ｧ縺阪∪縺吶・))
                }
            }
            .navigationTitle("謨咏ｧ・)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEditor = true
                    } label: {
                        Label("謨咏ｧ代ｒ霑ｽ蜉", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                SubjectEditorView()
            }
            .confirmationDialog(
                "縺薙・謨咏ｧ代ｒ螳悟・縺ｫ蜑企勁縺励∪縺吶°・・,
                item: $subjectPendingDeletion,
                titleVisibility: .visible
            ) { subject in
                Button("螳悟・縺ｫ蜑企勁", role: .destructive) {
                    permanentlyDelete(subject)
                }
                Button("繧ｭ繝｣繝ｳ繧ｻ繝ｫ", role: .cancel) {}
            } message: { subject in
                Text("\(subject.name) 繧貞炎髯､縺励∪縺吶る℃蜴ｻ縺ｮ險倬鹸縺ｯ縲梧蕗遘代↑縺励阪→縺励※谿九ｊ縺ｾ縺吶・)
            }
        }
    }

    private func moveSubjects(from source: IndexSet, to destination: Int) {
        var reordered = activeSubjects
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, subject) in reordered.enumerated() {
            subject.displayOrder = index
            subject.updatedAt = Date()
        }
    }

    private func archive(_ subject: Subject) {
        subject.isArchived = true
        subject.updatedAt = Date()
    }

    private func restore(_ subject: Subject) {
        subject.isArchived = false
        subject.displayOrder = activeSubjects.count
        subject.updatedAt = Date()
    }

    private func permanentlyDelete(_ subject: Subject) {
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
    }
}

private struct SubjectSummaryRow: View {
    let subject: Subject
    let sessions: [StudySession]

    private var todaySeconds: Int {
        StatisticsService.totalSecondsToday(for: subject, sessions: sessions)
    }

    private var weekSeconds: Int {
        StatisticsService.totalSecondsThisWeek(for: subject, sessions: sessions)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subject.iconName)
                .font(.title3)
                .frame(width: 34, height: 34)
                .background(ColorUtils.color(from: subject.colorHex).opacity(0.18), in: Circle())
                .foregroundStyle(ColorUtils.color(from: subject.colorHex))

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)
                Text("莉頑律 \(DateUtils.formatDuration(todaySeconds)) / 莉企ｱ \(DateUtils.formatDuration(weekSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if subject.dailyGoalSeconds > 0 {
                    ProgressView(value: StatisticsService.progressRatio(seconds: todaySeconds, goalSeconds: subject.dailyGoalSeconds))
                        .tint(ColorUtils.color(from: subject.colorHex))
                }
            }
        }
        .padding(.vertical, 2)
    }
}
