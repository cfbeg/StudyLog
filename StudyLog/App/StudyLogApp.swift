import Charts
import SwiftData
import SwiftUI

@main
struct StudyLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Subject.self,
            StudyTask.self,
            StudySession.self
        ])
    }
}

struct ContentView: View {
    @AppStorage("appTheme") private var appTheme = "system"

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("繝帙・繝", systemImage: "house.fill")
                }

            SubjectListView()
                .tabItem {
                    Label("謨咏ｧ・, systemImage: "books.vertical.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("邨ｱ險・, systemImage: "chart.bar.xaxis")
                }

            RecordListView()
                .tabItem {
                    Label("險倬鹸", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("險ｭ螳・, systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}

private struct StatisticsView: View {
    @Query(sort: \Subject.displayOrder) private var subjects: [Subject]
    @Query(sort: \StudyTask.createdAt, order: .reverse) private var tasks: [StudyTask]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    private var todaySubjectSummaries: [SubjectTimeSummary] {
        StatisticsService.subjectSummariesToday(subjects: subjects, sessions: sessions)
    }

    private var weekSummaries: [DailyTimeSummary] {
        StatisticsService.dailySummariesForCurrentWeek(sessions: sessions)
    }

    private var topTasks: [StudyTask] {
        tasks
            .filter { $0.spentSeconds > 0 }
            .sorted { $0.spentSeconds > $1.spentSeconds }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("莉頑律縺ｮ謨咏ｧ大挨") {
                    if todaySubjectSummaries.isEmpty {
                        ContentUnavailableView("莉頑律縺ｮ險倬鹸縺ｯ縺ｾ縺縺ゅｊ縺ｾ縺帙ｓ", systemImage: "chart.pie", description: Text("繧ｿ繧､繝槭・縺ｾ縺溘・謇句虚險倬鹸繧定ｿｽ蜉縺吶ｋ縺ｨ陦ｨ遉ｺ縺輔ｌ縺ｾ縺吶・))
                    } else {
                        Chart(todaySubjectSummaries) { summary in
                            SectorMark(
                                angle: .value("譎る俣", summary.seconds),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(ColorUtils.color(from: summary.colorHex))
                            .annotation(position: .overlay) {
                                if summary.seconds >= 600 {
                                    Text(summary.subjectName)
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 220)

                        ForEach(todaySubjectSummaries) { summary in
                            HStack {
                                Circle()
                                    .fill(ColorUtils.color(from: summary.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(summary.subjectName)
                                Spacer()
                                Text(DateUtils.formatDuration(summary.seconds))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("莉企ｱ縺ｮ譌･蛻･譎る俣") {
                    Chart(weekSummaries) { summary in
                        BarMark(
                            x: .value("譖懈律", summary.label),
                            y: .value("蛻・, summary.seconds / 60)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                    .frame(height: 200)
                }

                Section("繧ｿ繧ｹ繧ｯ蛻･縺ｮ菴ｿ逕ｨ譎る俣") {
                    if topTasks.isEmpty {
                        Text("繧ｿ繧ｹ繧ｯ縺ｫ邏舌▼縺・◆險倬鹸縺ｯ縺ｾ縺縺ゅｊ縺ｾ縺帙ｓ縲・)
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(Array(topTasks.prefix(8))) { task in
                            BarMark(
                                x: .value("蛻・, task.spentSeconds / 60),
                                y: .value("繧ｿ繧ｹ繧ｯ", task.title)
                            )
                            .foregroundStyle(.green.gradient)
                        }
                        .frame(height: max(180, CGFloat(min(topTasks.count, 8)) * 36))

                        ForEach(Array(topTasks.prefix(8))) { task in
                            HStack {
                                Text(task.title)
                                    .lineLimit(1)
                                Spacer()
                                Text(DateUtils.formatDuration(task.spentSeconds))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("邨ｱ險・)
        }
    }
}
