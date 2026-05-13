import SwiftUI

struct Pill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isActive ? Theme.Colors.cream : Theme.Colors.surface2)
                .foregroundColor(isActive ? Color(red: 0.1, green: 0.1, blue: 0.1) : Theme.Colors.text)
                .cornerRadius(Theme.Radius.pill)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = Theme.Colors.cream
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(isDisabled ? Theme.Colors.surface2 : color)
            .foregroundColor(isDisabled ? Theme.Colors.textMuted : Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(Theme.Radius.pill)
        }
        .disabled(isDisabled)
    }
}
