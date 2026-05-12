import SwiftUI

struct StyledCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
