import SwiftData
import SwiftUI

struct RecordListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var isShowingManualRecord = false

    private var groupedSessions: [(day: Date, title: String, sessions: [StudySession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }

        return grouped
            .map { item in
                (
                    day: item.key,
                    title: DateUtils.dateFormatter.string(from: item.key),
                    sessions: item.value.sorted { $0.startedAt > $1.startedAt }
                )
            }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            RecordListContent(
                sessions: sessions,
                groupedSessions: groupedSessions,
                deleteSessions: deleteSessions
            )
            .navigationTitle("Records")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingManualRecord = true
                    } label: {
                        Label("Manual record", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingManualRecord) {
                ManualRecordView()
            }
        }
    }

    private func deleteSessions(_ offsets: IndexSet, in groupSessions: [StudySession]) {
        for index in offsets {
            modelContext.delete(groupSessions[index])
        }
        try? modelContext.save()
    }
}

private struct RecordListContent: View {
    let sessions: [StudySession]
    let groupedSessions: [(day: Date, title: String, sessions: [StudySession])]
    let deleteSessions: (IndexSet, [StudySession]) -> Void

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No records yet",
                    systemImage: "calendar.badge.clock",
                    description: Text("Start the timer or add a manual record to create study logs.")
                )
            } else {
                ForEach(groupedSessions, id: \.day) { group in
                    Section(group.title) {
                        ForEach(group.sessions) { session in
                            SessionRow(session: session)
                        }
                        .onDelete { offsets in
                            deleteSessions(offsets, group.sessions)
                        }
                    }
                }
            }
        }
    }
}
