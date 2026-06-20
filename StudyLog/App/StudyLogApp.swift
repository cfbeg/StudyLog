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
                    Label("Home", systemImage: "house.fill")
                }

            SubjectListView()
                .tabItem {
                    Label("Subjects", systemImage: "books.vertical.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }

            RecordListView()
                .tabItem {
                    Label("Records", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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
            .navigationTitle("Stats")
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
        Section("Today by subject") {
            if summaries.isEmpty {
                ContentUnavailableView(
                    "No study logged today",
                    systemImage: "chart.pie",
                    description: Text("Start the timer or add a manual record to see the chart.")
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
                angle: .value("Seconds", summary.seconds),
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
        Section("This week") {
            Chart(summaries) { summary in
                BarMark(
                    x: .value("Day", summary.label),
                    y: .value("Minutes", summary.seconds / 60)
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
        Section("Top tasks by time") {
            if tasks.isEmpty {
                Text("No task-linked study sessions yet.")
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
                x: .value("Minutes", task.spentSeconds / 60),
                y: .value("Task", task.title)
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
