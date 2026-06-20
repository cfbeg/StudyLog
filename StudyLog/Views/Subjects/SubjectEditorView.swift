import SwiftData
import SwiftUI

struct SubjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var subject: Subject?

    @State private var name: String
    @State private var colorHex: String
    @State private var iconName: String
    @State private var dailyGoalMinutes: Int
    @State private var weeklyGoalMinutes: Int

    init(subject: Subject? = nil) {
        self.subject = subject
        _name = State(initialValue: subject?.name ?? "")
        _colorHex = State(initialValue: subject?.colorHex ?? ColorUtils.defaultSubjectColors[0])
        _iconName = State(initialValue: subject?.iconName ?? "book.closed.fill")
        _dailyGoalMinutes = State(initialValue: (subject?.dailyGoalSeconds ?? 0) / 60)
        _weeklyGoalMinutes = State(initialValue: (subject?.weeklyGoalSeconds ?? 0) / 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("教科名", text: $name)
                    TextField("SF Symbols アイコン名", text: $iconName)
                }

                Section("色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                        ForEach(ColorUtils.defaultSubjectColors, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(ColorUtils.color(from: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .bold()
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    TextField("#3B82F6", text: $colorHex)
                        .textInputAutocapitalization(.characters)
                }

                Section("目標") {
                    Stepper("1日 (dailyGoalMinutes) 分", value: $dailyGoalMinutes, in: 0...600, step: 10)
                    Stepper("1週間 (weeklyGoalMinutes) 分", value: $weeklyGoalMinutes, in: 0...5000, step: 30)
                }

                if let subject {
                    Section {
                        Button(role: .destructive) {
                            subject.isArchived = true
                            subject.updatedAt = Date()
                            dismiss()
                        } label: {
                            Label("この教科をアーカイブ", systemImage: "archivebox")
                        }
                    } footer: {
                        Text("履歴を残すため、削除ではなく非表示にします。")
                    }
                }
            }
            .navigationTitle(subject == nil ? "教科を追加" : "教科を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let subject {
            subject.name = trimmedName
            subject.colorHex = colorHex
            subject.iconName = iconName
            subject.dailyGoalSeconds = dailyGoalMinutes * 60
            subject.weeklyGoalSeconds = weeklyGoalMinutes * 60
            subject.updatedAt = Date()
        } else {
            let subject = Subject(
                name: trimmedName,
                colorHex: colorHex,
                iconName: iconName,
                dailyGoalSeconds: dailyGoalMinutes * 60,
                weeklyGoalSeconds: weeklyGoalMinutes * 60
            )
            modelContext.insert(subject)
        }

        dismiss()
    }
}
