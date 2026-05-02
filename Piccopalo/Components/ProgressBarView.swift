import SwiftUI

struct ProgressBarView: View {
    let percentage: Double

    private var barColor: Color {
        switch percentage {
        case ..<50:   return .yellow
        case 50..<90: return .orange
        default:      return .green
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 8)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(min(percentage / 100, 1)))
                    .animation(.easeInOut(duration: 0.5), value: percentage)
            }
        }
        .frame(height: 20)
    }
}
