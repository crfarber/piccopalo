import SwiftUI

struct SwipeableActionRow<Content: View>: View {
    let id: String
    @Binding var openID: String?
    var onEdit: (() -> Void)? = nil
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0

    private let buttonWidth: CGFloat = 64
    private var openWidth: CGFloat { buttonWidth * CGFloat((onEdit == nil ? 1 : 2)) }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                if let onEdit {
                    actionButton(icon: "pencil", background: Theme.Colors.cream, foreground: Theme.Colors.background, action: {
                        close()
                        onEdit()
                    })
                }
                actionButton(icon: "trash", background: Theme.Colors.tomato, foreground: .white) {
                    close()
                    onDelete()
                }
            }

            content
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .background(Theme.Colors.tomato)
        .clipped()
        .onChange(of: openID) { _, newValue in
            if newValue != id, offset != 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { offset = 0 }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let base = openID == id ? -openWidth : 0
                offset = min(max(base + value.translation.width, -openWidth), 0)
            }
            .onEnded { value in
                let projected = offset + value.predictedEndTranslation.width * 0.2
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    if projected < -openWidth / 2 {
                        offset = -openWidth
                        openID = id
                    } else {
                        offset = 0
                        if openID == id { openID = nil }
                    }
                }
            }
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { offset = 0 }
        if openID == id { openID = nil }
    }

    private func actionButton(
        icon: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(foreground)
                .frame(width: buttonWidth)
                .frame(maxHeight: .infinity)
                .background(background)
        }
        .buttonStyle(.plain)
    }
}
