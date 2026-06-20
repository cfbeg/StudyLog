import SwiftData
import SwiftUI

struct RecordListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var isShowingManualRecord = false

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    ContentUnavailableView("記録がありません", systemImage: "calendar.badge.clock", description: Text("タイマーまたは手動記録から勉強ログを追加できます。"))
                } else {
                    ForEach(groupedSessions, id: \.day) { group in
                        Section(group.title) {
                            ForEach(group.sessions) { session in
                                SessionRow(session: session)
                            }
                            .onDelete { offsets in
                                deleteSessions(offsets, in: group.sessions)
                            }
                        }
                    }
                }
            }
            .navigationTitle("記録")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingManualRecord = true
                    } label: {
                        Label("手動記録", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingManualRecord) {
                ManualRecordView()
            }
        }
    }

    private var groupedSessions: [(day: Date, title: String, sessions: [StudySession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }

        return grouped
            .map { (day: $0.key, title: DateUtils.dateFormatter.string(from: $0.key), sessions: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.day > $1.day }
    }

    private func deleteSessions(_ offsets: IndexSet, in groupSessions: [StudySession]) {
        for index in offsets {
            modelContext.delete(groupSessions[index])
        }
    }
}
