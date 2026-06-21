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
                    Label("ホーム", systemImage: "house.fill")
                }

            SubjectListView()
                .tabItem {
                    Label("教科", systemImage: "books.vertical.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.xaxis")
                }

            RecordListView()
                .tabItem {
                    Label("記録", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
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
            StatisticsList(
                todaySubjectSummaries: todaySubjectSummaries,
                weekSummaries: weekSummaries,
                topTasks: Array(topTasks.prefix(8))
            )
            .navigationTitle("統計")
        }
    }
}

private struct StatisticsList: View {
    let todaySubjectSummaries: [SubjectTimeSummary]
    let weekSummaries: [DailyTimeSummary]
    let topTasks: [StudyTask]

    var body: some View {
        List {
            TodaySubjectChartSection(summaries: todaySubjectSummaries)
            WeeklyBarChartSection(summaries: weekSummaries)
            TopTaskChartSection(tasks: topTasks)
        }
    }
}

private struct TodaySubjectChartSection: View {
    let summaries: [SubjectTimeSummary]

    var body: some View {
        Section("今日の教科別時間") {
            if summaries.isEmpty {
                ContentUnavailableView(
                    "今日はまだ記録がありません",
                    systemImage: "chart.pie",
                    description: Text("タイマーを使うか手動記録を追加すると、グラフが表示されます。")
                )
            } else {
                TodaySubjectDonutChart(summaries: summaries)
                TodaySubjectLegend(summaries: summaries)
            }
        }
    }
}

private struct TodaySubjectDonutChart: View {
    let summaries: [SubjectTimeSummary]

    var body: some View {
        Chart(summaries) { summary in
            SectorMark(
                angle: .value("秒", summary.seconds),
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
    }
}

private struct TodaySubjectLegend: View {
    let summaries: [SubjectTimeSummary]

    var body: some View {
        ForEach(summaries) { summary in
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

private struct WeeklyBarChartSection: View {
    let summaries: [DailyTimeSummary]

    var body: some View {
        Section("今週") {
            Chart(summaries) { summary in
                BarMark(
                    x: .value("日", summary.label),
                    y: .value("分", summary.seconds / 60)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 200)
        }
    }
}

private struct TopTaskChartSection: View {
    let tasks: [StudyTask]

    private var chartHeight: CGFloat {
        max(180, CGFloat(tasks.count) * 36)
    }

    var body: some View {
        Section("時間の多いタスク") {
            if tasks.isEmpty {
                Text("タスクに紐づいた勉強記録はまだありません。")
                    .foregroundStyle(.secondary)
            } else {
                TopTaskBarChart(tasks: tasks)
                    .frame(height: chartHeight)
                TopTaskLegend(tasks: tasks)
            }
        }
    }
}

private struct TopTaskBarChart: View {
    let tasks: [StudyTask]

    var body: some View {
        Chart(tasks) { task in
            BarMark(
                x: .value("分", task.spentSeconds / 60),
                y: .value("タスク", task.title)
            )
            .foregroundStyle(.green.gradient)
        }
    }
}

private struct TopTaskLegend: View {
    let tasks: [StudyTask]

    var body: some View {
        ForEach(tasks) { task in
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
