import SwiftUI

// MARK: - Core reusable vertical bar

struct VerticalProgressBar: View {
    enum Style {
        case pastaGradient
        case statusTint
    }

    let percentage: Double
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat?
    var style: Style = .pastaGradient
    var trackColor: Color?
    var showGlow: Bool = false
    var outlineLineWidth: CGFloat = 1.5
    var outlineOpacity: CGFloat = 0.14

    private var clamped: Double {
        min(max(percentage, 0), 100)
    }

    private var effectiveCorner: CGFloat {
        cornerRadius ?? max(6, min(width, height) * 0.22)
    }

    private var pastaGradientHero: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Theme.Colors.layerC, location: 0),
                .init(color: Theme.Colors.layerB, location: 0.28),
                .init(color: Theme.Colors.layerA, location: 0.55),
                .init(color: Theme.Colors.layerD, location: 1),
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var pastaGradientCompact: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Theme.Colors.layerC, location: 0),
                .init(color: Theme.Colors.layerB, location: 0.3),
                .init(color: Theme.Colors.layerA, location: 0.62),
                .init(color: Theme.Colors.layerD, location: 1),
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var pastaGradient: LinearGradient {
        height > 72 ? pastaGradientHero : pastaGradientCompact
    }

    private var glowAccentColor: Color {
        if clamped >= 90 { return Theme.Colors.green }
        if clamped >= 50 { return Theme.Colors.creamDeep }
        return Theme.Colors.tomato
    }

    private var statusFillColor: Color {
        clamped >= 100 ? Theme.Colors.green : g.Colors.creamDeep
    }

    private var defaultTrack: Color {
        switch style {
        case .pastaGradient:
            return Theme.Colors.surface
        case .statusTint:
            return Theme.Colors.surface2
        }
    }

    @ViewBuilder
    private func fillShape(height: CGFloat) -> some View {
        switch style {
        case .pastaGradient:
            RoundedRectangle(cornerRadius: effectiveCorner, style: .continuous)
                .fill(pastaGradient)
                .frame(height: height)
        case .statusTint:
            RoundedRectangle(cornerRadius: effectiveCorner, style: .continuous)
                .fill(statusFillColor)
                .frame(height: height)
        }
    }

    var body: some View {
        let corner = effectiveCorner
        let track = trackColor ?? defaultTrack
        let fillH = height * (clamped / 100)

        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(track)

            fillShape(height: fillH)
                .animation(.easeInOut(duration: 0.45), value: clamped)

            if showGlow && style == .pastaGradient && clamped > 5 {
                Ellipse()
                    .fill(glowAccentColor.opacity(0.2))
                    .frame(width: width * 0.72, height: max(2, height * 0.05))
                    .blur(radius: 6)
                    .offset(y: (height / 2) - fillH)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.white.opacity(outlineOpacity), lineWidth: outlineLineWidth)
        )
    }
}

// MARK: - Presets (existing call sites)

struct ProgressBar: View {
    let percentage: Double
    let size: CGFloat
    let showGlow: Bool

    init(percentage: Double, size: CGFloat = 200, showGlow: Bool = true) {
        self.percentage = percentage
        self.size = size
        self.showGlow = showGlow
    }

    var body: some View {
        VerticalProgressBar(
            percentage: percentage,
            width: size,
            height: size * 1.2,
            cornerRadius: 22,
            style: .pastaGradient,
            showGlow: showGlow,
            outlineLineWidth: 1.5,
            outlineOpacity: 0.14
        )
    }
}

struct ProgressBarMini: View {
    let percentage: Double
    let size: CGFloat = 36

    var body: some View {
        VerticalProgressBar(
            percentage: percentage,
            width: size * 0.42,
            height: size,
            cornerRadius: 8,
            style: .pastaGradient,
            showGlow: false,
            outlineLineWidth: 1,
            outlineOpacity: 0.16
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(percentage: 0)
        ProgressBar(percentage: 45)
        ProgressBar(percentage: 68)
        ProgressBar(percentage: 95)
        ProgressBar(percentage: 100)

        HStack(spacing: 12) {
            VerticalProgressBar(percentage: 69, width: 14, height: 56, style: .statusTint, outlineLineWidth: 1, outlineOpacity: 0.16)
            VerticalProgressBar(percentage: 100, width: 14, height: 56, style: .statusTint, outlineLineWidth: 1, outlineOpacity: 0.16)
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
