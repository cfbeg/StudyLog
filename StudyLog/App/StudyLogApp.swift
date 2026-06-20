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

            RecordListView()
                .tabItem {
                    Label("記録", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}
