import SwiftUI

struct AppButton: View {
    enum Size: Equatable {
        case small
        case medium
        case fullWidth
        case square(CGFloat)
    }

    enum CornerStyle {
        case pill
        case rounded(CGFloat)
    }

    var title: String?
    var icon: String?
    var size: Size = .medium
    var background: Color = Theme.Colors.surface2
    var foreground: Color = Theme.Colors.text
    var cornerStyle: CornerStyle = .rounded(Theme.Radius.md)
    var isDisabled: Bool = false
    let action: () -> Void

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return Theme.Spacing.md
        case .medium, .fullWidth: return Theme.Spacing.md
        case .square: return 0
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return Theme.Spacing.sm
        case .medium, .fullWidth: return Theme.Spacing.md
        case .square: return 0
        }
    }

    private var titleFont: Font {
        switch size {
        case .small: return .system(size: 15, weight: .semibold)
        case .medium, .fullWidth, .square: return .system(size: 16, weight: .semibold)
        }
    }

    private var cornerRadius: CGFloat {
        switch cornerStyle {
        case .pill: return Theme.Radius.pill
        case let .rounded(value): return value
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }

                if let title {
                    Text(title)
                        .font(titleFont)
                }
            }
            .frame(maxWidth: size == .fullWidth ? .infinity : nil)
            .frame(width: squareSize, height: squareSize)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .foregroundColor(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .opacity(isDisabled ? 0.65 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var squareSize: CGFloat? {
        if case let .square(value) = size {
            return value
        }
        return nil
    }
}

struct Pill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        AppButton(
            title: title,
            icon: nil,
            size: .small,
            background: isActive ? Theme.Colors.cream : Theme.Colors.surface2,
            foreground: isActive ? Color(red: 0.1, green: 0.1, blue: 0.1) : Theme.Colors.text,
            cornerStyle: .pill,
            action: action
        )
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = Theme.Colors.cream
    var isDisabled: Bool = false

    var body: some View {
        AppButton(
            title: title,
            icon: icon,
            size: .fullWidth,
            background: isDisabled ? Theme.Colors.surface2 : color,
            foreground: isDisabled ? Theme.Colors.textMuted : Color(red: 0.1, green: 0.1, blue: 0.1),
            cornerStyle: .pill,
            isDisabled: isDisabled,
            action: action
        )
    }
}

