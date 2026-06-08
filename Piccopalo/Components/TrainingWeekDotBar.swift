import SwiftUI

struct TrainingWeekDotBar: View {
    let states: [TrainingWeekDayDotState]

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let count = max(states.count, 1)
            let totalSpacing = spacing * CGFloat(count - 1)
            let dotWidth = (geo.size.width - totalSpacing) / CGFloat(count)

            HStack(spacing: spacing) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: state))
                        .frame(width: dotWidth, height: 8)
                }
            }
        }
        .frame(height: 8)
    }

    private func color(for state: TrainingWeekDayDotState) -> Color {
        switch state {
        case .completed:
            return Theme.Colors.green
        case .planned:
            return Theme.Colors.green.opacity(0.35)
        case .missed:
            return Theme.Colors.tomato.opacity(0.45)
        case .empty:
            return Color.white.opacity(0.08)
        }
    }
}
