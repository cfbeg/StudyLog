import SwiftUI

struct SessionRow: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.subject?.name ?? "教科なし")
                    .font(.headline)
                Spacer()
                Text(DateUtils.formatDuration(session.durationSeconds))
                    .font(.subheadline.bold())
            }

            HStack(spacing: 8) {
                if let task = session.task {
                    Text(task.title)
                }
                Text(DateUtils.dateTimeFormatter.string(from: session.startedAt))
                if session.isManual {
                    Text("手動")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !session.memo.isEmpty {
                Text(session.memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}