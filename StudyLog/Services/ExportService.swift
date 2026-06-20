import Foundation

enum ExportService {
    static func csvRows(for sessions: [StudySession]) -> String {
        let header = "date,startedAt,endedAt,subject,task,durationMinutes,memo,isManual"
        let rows = sessions.map { session in
            [
                DateUtils.dateFormatter.string(from: session.startedAt),
                DateUtils.dateTimeFormatter.string(from: session.startedAt),
                DateUtils.dateTimeFormatter.string(from: session.endedAt),
                session.subject?.name ?? "",
                session.task?.title ?? "",
                String(session.durationSeconds / 60),
                session.memo,
                session.isManual ? "true" : "false"
            ]
            .map(csvEscape)
            .joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    static func makeCSVFile(sessions: [StudySession]) throws -> URL {
        let fileName = "StudyLog-\(DateUtils.fileNameDateFormatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvRows(for: sessions).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
