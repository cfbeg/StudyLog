import SwiftUI

struct TaskRow: View {
    let task: StudyTask
    let showsSubject: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.status == .completed ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    if showsSubject, let subject = task.subject {
                        Text(subject.name)
                    }
                    Text(task.status.displayName)
                    Text("実績 (DateUtils.formatDuration(task.spentSeconds))")
                    if task.estimatedSeconds > 0 {
                        Text("予定 (DateUtils.formatDuration(task.estimatedSeconds))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
