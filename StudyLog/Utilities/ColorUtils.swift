import SwiftUI

enum ColorUtils {
    static let defaultSubjectColors = [
        "#3B82F6",
        "#EF4444",
        "#22C55E",
        "#F97316",
        "#8B5CF6",
        "#06B6D4",
        "#EC4899",
        "#64748B"
    ]

    static func color(from hex: String) -> Color {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        raw = raw.replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}
