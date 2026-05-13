import SwiftUI

struct SectionLabel: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.4)
                .textCase(.uppercase)
        }
        .foregroundColor(Theme.Colors.textMuted)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
    }
}
