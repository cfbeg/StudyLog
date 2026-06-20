import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 120
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = true
    @AppStorage("appTheme") private var appTheme = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section("目標") {
                    Stepper("1日の目標 \(dailyGoalMinutes) 分", value: $dailyGoalMinutes, in: 0...720, step: 15)
                    Toggle("週の開始を月曜日にする", isOn: $weekStartsOnMonday)
                }

                Section("通知") {
                    Label("毎日の記録リマインダー", systemImage: "bell")
                    Label("タスク期限前日の通知", systemImage: "calendar.badge.exclamationmark")
                    Text("v0.2 で通知許可フローとスケジュール登録を追加予定です。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("データ") {
                    Label("CSV エクスポート", systemImage: "square.and.arrow.up")
                    Label("データ全削除", systemImage: "trash")
                    Text("v0.2 でエクスポートと安全な全削除確認を追加予定です。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("テーマ") {
                    Picker("アプリテーマ", selection: $appTheme) {
                        Text("システム").tag("system")
                        Text("ライト").tag("light")
                        Text("ダーク").tag("dark")
                    }
                }

                Section("このアプリ") {
                    Text("教科を作る → タスクを作る → タスクを選んでタイマー開始、という軽い流れを中心にしたオフライン学習ログです。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
        }
    }
}
