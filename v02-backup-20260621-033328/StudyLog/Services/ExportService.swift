import Foundation

enum ExportService {
    static func csvRows(for sessions: [StudySession]) -> String {
        let header = "date,subject,task,durationMinutes,memo"
        let rows = sessions.map { session in
            [
                DateUtils.dateTimeFormatter.string(from: session.startedAt),
                session.subject?.name ?? "",
                session.task?.title ?? "",
                String(session.durationSeconds / 60),
                session.memo.replacingOccurrences(of: ",", with: " ")
            ].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }
}
