import SwiftUI

struct RingProgressView: View {
    let consumed: Double
    let goal: Double
    let lineWidth: CGFloat

    private var percentage: Double {
        guard goal > 0 else { return 0 }
        return min(consumed / goal, 1)
    }

    init(consumed: Double, goal: Double, lineWidth: CGFloat = 20) {
        self.consumed = consumed
        self.goal = goal
        self.lineWidth = lineWidth
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Track
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(
                        LinearGradient(
                            colors: [DesignTokens.Colors.green.opacity(0.75), DesignTokens.Colors.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: percentage)

                // Center
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", consumed))
                        .font(.system(size: size * 0.23, weight: .bold, design: .default))
                        .foregroundColor(DesignTokens.Colors.text)
                        .monospacedDigit()

                    Text("VAN \(Int(goal))G EIWIT")
                        .font(.system(size: size * 0.055, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textMuted)
                        .tracking(0.8)
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
