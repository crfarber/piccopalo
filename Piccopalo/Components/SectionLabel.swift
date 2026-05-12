import SwiftUI

struct SectionLabel: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.4)
                .textCase(.uppercase)
        }
        .foregroundColor(DesignTokens.Colors.textMuted)
        .padding(.top, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.sm)
    }
}
