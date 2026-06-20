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
                Section("蝓ｺ譛ｬ") {
                    TextField("謨咏ｧ大錐", text: $name)
                    TextField("SF Symbols 繧｢繧､繧ｳ繝ｳ蜷・, text: $iconName)
                }

                Section("濶ｲ") {
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

                Section("逶ｮ讓・) {
                    Stepper("1譌･ \(dailyGoalMinutes) 蛻・, value: $dailyGoalMinutes, in: 0...600, step: 10)
                    Stepper("1騾ｱ髢・\(weeklyGoalMinutes) 蛻・, value: $weeklyGoalMinutes, in: 0...5000, step: 30)
                }

                if let subject {
                    Section {
                        Button(role: .destructive) {
                            subject.isArchived = true
                            subject.updatedAt = Date()
                            dismiss()
                        } label: {
                            Label("縺薙・謨咏ｧ代ｒ繧｢繝ｼ繧ｫ繧､繝・, systemImage: "archivebox")
                        }
                    } footer: {
                        Text("螳悟・蜑企勁縺ｯ謨咏ｧ題ｩｳ邏ｰ縺ｾ縺溘・謨咏ｧ台ｸ隕ｧ縺ｮ繝｡繝九Η繝ｼ縺九ｉ螳溯｡後〒縺阪∪縺吶・)
                    }
                }
            }
            .navigationTitle(subject == nil ? "謨咏ｧ代ｒ霑ｽ蜉" : "謨咏ｧ代ｒ邱ｨ髮・)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("繧ｭ繝｣繝ｳ繧ｻ繝ｫ") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("菫晏ｭ・) {
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
