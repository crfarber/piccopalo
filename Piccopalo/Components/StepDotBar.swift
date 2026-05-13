import SwiftUI

struct StepDotBar: View {
    let steps: Int
    let goal: Int
    var dotCount: Int = 20

    private var filledDots: Int {
        guard goal > 0 else { return 0 }
        return min(Int((Double(steps) / Double(goal)) * Double(dotCount)), dotCount)
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let totalSpacing = spacing * CGFloat(dotCount - 1)
            let dotWidth = (geo.size.width - totalSpacing) / CGFloat(dotCount)

            HStack(spacing: spacing) {
                ForEach(0..<dotCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i < filledDots ? Theme.Colors.green : Color.white.opacity(0.08))
                        .frame(width: dotWidth, height: 8)
                }
            }
        }
        .frame(height: 8)
    }
}
