import SwiftUI

struct StyledCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
