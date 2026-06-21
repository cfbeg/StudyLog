import SwiftData
import SwiftUI

struct SubjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    @State private var isShowingEditor = false
    @State private var subjectPendingDeletion: Subject?
    @State private var isShowingDeleteConfirmation = false

    private var activeSubjects: [Subject] {
        subjects.filter { !$0.isArchived }
    }

    private var archivedSubjects: [Subject] {
        subjects.filter(\.isArchived)
    }

    var body: some View {
        NavigationStack {
            SubjectListContent(
                activeSubjects: activeSubjects,
                archivedSubjects: archivedSubjects,
                sessions: sessions,
                moveSubjects: moveSubjects,
                archive: archive,
                restore: restore,
                requestDelete: { subject in
                    subjectPendingDeletion = subject
                    isShowingDeleteConfirmation = true
                }
            )
            .navigationTitle("教科")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEditor = true
                    } label: {
                        Label("教科を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                SubjectEditorView()
            }
            .confirmationDialog(
                "この教科を削除しますか？",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible,
                actions: {
                Button("完全に削除", role: .destructive) {
                    if let subject = subjectPendingDeletion {
                        permanentlyDelete(subject)
                    }
                    subjectPendingDeletion = nil
                }
                Button("キャンセル", role: .cancel) {
                    subjectPendingDeletion = nil
                }
            },
                message: {
                Text(deleteConfirmationMessage)
            })
        }
    }

    private var deleteConfirmationMessage: String {
        guard let subject = subjectPendingDeletion else {
            return "過去の勉強記録は「教科なし」の記録として残ります。"
        }

        return "\(subject.name)を削除します。過去の勉強記録は「教科なし」の記録として残ります。"
    }

    private func moveSubjects(from source: IndexSet, to destination: Int) {
        var reordered = activeSubjects
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, subject) in reordered.enumerated() {
            subject.displayOrder = index
            subject.updatedAt = Date()
        }

        try? modelContext.save()
    }

    private func archive(_ subject: Subject) {
        subject.isArchived = true
        subject.updatedAt = Date()
        try? modelContext.save()
    }

    private func restore(_ subject: Subject) {
        subject.isArchived = false
        subject.displayOrder = activeSubjects.count
        subject.updatedAt = Date()
        try? modelContext.save()
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

private struct SubjectListContent: View {
    let activeSubjects: [Subject]
    let archivedSubjects: [Subject]
    let sessions: [StudySession]
    let moveSubjects: (IndexSet, Int) -> Void
    let archive: (Subject) -> Void
    let restore: (Subject) -> Void
    let requestDelete: (Subject) -> Void

    var body: some View {
        List {
            ActiveSubjectSection(
                subjects: activeSubjects,
                sessions: sessions,
                moveSubjects: moveSubjects,
                archive: archive,
                requestDelete: requestDelete
            )

            if !archivedSubjects.isEmpty {
                ArchivedSubjectSection(
                    subjects: archivedSubjects,
                    sessions: sessions,
                    restore: restore,
                    requestDelete: requestDelete
                )
            }

            if activeSubjects.isEmpty {
                SubjectEmptySection()
            }
        }
    }
}

private struct ActiveSubjectSection: View {
    let subjects: [Subject]
    let sessions: [StudySession]
    let moveSubjects: (IndexSet, Int) -> Void
    let archive: (Subject) -> Void
    let requestDelete: (Subject) -> Void

    var body: some View {
        Section {
            ForEach(subjects) { subject in
                SubjectNavigationRow(subject: subject, sessions: sessions)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        SubjectDeleteButton(subject: subject, requestDelete: requestDelete)
                        SubjectArchiveButton(subject: subject, archive: archive)
                    }
            }
            .onMove(perform: moveSubjects)
        } header: {
            Text("使用中")
        } footer: {
            Text("編集で並び替えできます。教科を削除しても、過去の勉強記録は「教科なし」として残ります。")
        }
    }
}

private struct ArchivedSubjectSection: View {
    let subjects: [Subject]
    let sessions: [StudySession]
    let restore: (Subject) -> Void
    let requestDelete: (Subject) -> Void

    var body: some View {
        Section("アーカイブ済み") {
            ForEach(subjects) { subject in
                SubjectSummaryRow(subject: subject, sessions: sessions)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        SubjectDeleteButton(subject: subject, requestDelete: requestDelete)
                        SubjectRestoreButton(subject: subject, restore: restore)
                    }
            }
        }
    }
}

private struct SubjectNavigationRow: View {
    let subject: Subject
    let sessions: [StudySession]

    var body: some View {
        NavigationLink {
            SubjectDetailView(subject: subject)
        } label: {
            SubjectSummaryRow(subject: subject, sessions: sessions)
        }
    }
}

private struct SubjectDeleteButton: View {
    let subject: Subject
    let requestDelete: (Subject) -> Void

    var body: some View {
        Button(role: .destructive) {
            requestDelete(subject)
        } label: {
            Label("削除", systemImage: "trash")
        }
    }
}

private struct SubjectArchiveButton: View {
    let subject: Subject
    let archive: (Subject) -> Void

    var body: some View {
        Button {
            archive(subject)
        } label: {
            Label("アーカイブ", systemImage: "archivebox")
        }
        .tint(.orange)
    }
}

private struct SubjectRestoreButton: View {
    let subject: Subject
    let restore: (Subject) -> Void

    var body: some View {
        Button {
            restore(subject)
        } label: {
            Label("戻す", systemImage: "arrow.uturn.backward")
        }
        .tint(.green)
    }
}

private struct SubjectEmptySection: View {
    var body: some View {
        ContentUnavailableView(
            "教科がありません",
            systemImage: "books.vertical",
            description: Text("＋ボタンから最初の教科を追加してください。")
        )
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

    private var subjectColor: Color {
        ColorUtils.color(from: subject.colorHex)
    }

    private var subtitle: String {
        "今日 \(DateUtils.formatDuration(todaySeconds)) / 今週 \(DateUtils.formatDuration(weekSeconds))"
    }

    var body: some View {
        HStack(spacing: 12) {
            SubjectIconView(iconName: subject.iconName, color: subjectColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if subject.dailyGoalSeconds > 0 {
                    ProgressView(value: StatisticsService.progressRatio(seconds: todaySeconds, goalSeconds: subject.dailyGoalSeconds))
                        .tint(subjectColor)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SubjectIconView: View {
    let iconName: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.title3)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.18), in: Circle())
            .foregroundStyle(color)
    }
}
