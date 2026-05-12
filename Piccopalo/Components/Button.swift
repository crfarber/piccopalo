import SwiftUI

struct Pill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(isActive ? DesignTokens.Colors.cream : DesignTokens.Colors.surface2)
                .foregroundColor(isActive ? Color(red: 0.1, green: 0.1, blue: 0.1) : DesignTokens.Colors.text)
                .cornerRadius(DesignTokens.Radius.pill)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = DesignTokens.Colors.cream
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
            .background(isDisabled ? DesignTokens.Colors.surface2 : color)
            .foregroundColor(isDisabled ? DesignTokens.Colors.textMuted : Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(DesignTokens.Radius.pill)
        }
        .disabled(isDisabled)
    }
}
