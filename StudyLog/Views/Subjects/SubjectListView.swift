import SwiftData
import SwiftUI

struct SubjectListView: View {
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var isShowingEditor = false

    private var activeSubjects: [Subject] {
        subjects.filter { !$0.isArchived }
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
                    }
                }

                if activeSubjects.isEmpty {
                    ContentUnavailableView("教科がありません", systemImage: "books.vertical", description: Text("右上の追加ボタンから教科を作成できます。"))
                }
            }
            .navigationTitle("教科")
            .toolbar {
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
        }
    }
}

private struct SubjectSummaryRow: View {
    let subject: Subject
    let sessions: [StudySession]

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
                Text("今日 (DateUtils.formatDuration(StatisticsService.totalSecondsToday(for: subject, sessions: sessions))) / 今週 (DateUtils.formatDuration(StatisticsService.totalSecondsThisWeek(for: subject, sessions: sessions)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
