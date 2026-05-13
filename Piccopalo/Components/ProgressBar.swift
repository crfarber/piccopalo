import SwiftUI

struct StyledProgressBar: View {
    let percentage: Double

    var barColor: Color {
        switch percentage {
        case ..<50: return Theme.Colors.tomato
        case 50..<90: return Theme.Colors.creamDeep
        default: return Theme.Colors.green
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
        .frame(height: 30)
    }
}
