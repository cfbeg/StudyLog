import SwiftData
import SwiftUI

struct SubjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let subject: Subject?

    @State private var name: String
    @State private var colorHex: String
    @State private var iconName: String
    @State private var dailyGoalMinutes: Int
    @State private var weeklyGoalMinutes: Int
    @State private var isArchived: Bool

    private let iconChoices = ["book.closed.fill", "function", "text.book.closed.fill", "scroll.fill", "flask.fill", "atom", "globe.asia.australia.fill", "desktopcomputer"]

    init(subject: Subject? = nil) {
        self.subject = subject
        _name = State(initialValue: subject?.name ?? "")
        _colorHex = State(initialValue: subject?.colorHex ?? ColorUtils.defaultSubjectColors.first ?? "#3B82F6")
        _iconName = State(initialValue: subject?.iconName ?? "book.closed.fill")
        _dailyGoalMinutes = State(initialValue: (subject?.dailyGoalSeconds ?? 0) / 60)
        _weeklyGoalMinutes = State(initialValue: (subject?.weeklyGoalSeconds ?? 0) / 60)
        _isArchived = State(initialValue: subject?.isArchived ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Subject name", text: $name)

                    Picker("Icon", selection: $iconName) {
                        ForEach(iconChoices, id: \.self) { icon in
                            Label(icon, systemImage: icon).tag(icon)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                        ForEach(ColorUtils.defaultSubjectColors, id: \.self) { hex in
                            Circle()
                                .fill(ColorUtils.color(from: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.caption.bold())
                                    }
                                }
                                .onTapGesture {
                                    colorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Goals") {
                    Stepper("Daily \(dailyGoalMinutes) min", value: $dailyGoalMinutes, in: 0...720, step: 15)
                    Stepper("Weekly \(weeklyGoalMinutes) min", value: $weeklyGoalMinutes, in: 0...5000, step: 30)
                }

                if subject != nil {
                    Section("Archive") {
                        Toggle("Archive this subject", isOn: $isArchived)
                    }
                }
            }
            .navigationTitle(subject == nil ? "Add subject" : "Edit subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
            subject.isArchived = isArchived
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

        try? modelContext.save()
        dismiss()
    }
}