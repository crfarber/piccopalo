import SwiftUI

// Primary Button
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

// Card
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

// Row with label and value
struct DetailRow: View {
    let label: String
    let value: String
    let valueColor: Color

    init(_ label: String, _ value: String, color: Color = DesignTokens.Colors.text) {
        self.label = label
        self.value = value
        self.valueColor = color
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(DesignTokens.Colors.textMuted)
                .font(.system(size: 15, weight: .regular))

            Spacer()

            Text(value)
                .foregroundColor(valueColor)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .monospacedDigit()
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

// Pill button
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

// Section label
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

// Progress bar with color change
struct StyledProgressBar: View {
    let percentage: Double

    var barColor: Color {
        switch percentage {
        case ..<50: return DesignTokens.Colors.tomato
        case 50..<90: return DesignTokens.Colors.creamDeep
        default: return DesignTokens.Colors.green
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white.opacity(0.06))

                RoundedRectangle(cornerRadius: 5)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(min(percentage / 100, 1)))
                    .animation(.easeInOut(duration: 0.6), value: percentage)
            }
        }
        .frame(height: 10)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Add Protein", icon: "plus", action: {})
        PrimaryButton(title: "Disabled", icon: nil, action: {}, isDisabled: true)

        StyledCard {
            VStack(spacing: 12) {
                DetailRow("Dagdoel", "140g")
                Divider()
                    .background(Color.white.opacity(0.08))
                DetailRow("Gegeten", "96g", color: DesignTokens.Colors.green)
            }
        }

        HStack(spacing: 8) {
            Pill(title: "Alles", isActive: true) { }
            Pill(title: "Vlees", isActive: false) { }
            Pill(title: "Vis", isActive: false) { }
        }

        StyledProgressBar(percentage: 68)
    }
    .padding()
    .background(DesignTokens.Colors.background)
}

