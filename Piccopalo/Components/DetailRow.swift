import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String
    let valueColor: Color

    init(_ label: String, _ value: String, color: Color = Theme.Colors.text) {
        self.label = label
        self.value = value
        self.valueColor = color
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(Theme.Colors.textMuted)
                .font(.system(size: 15, weight: .regular))

            Spacer()

            Text(value)
                .foregroundColor(valueColor)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .monospacedDigit()
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}
