import SwiftUI

struct DualRingProgressView: View {
    let proteinPercentage: Double
    let waterPercentage: Double
    let proteinConsumed: Double
    let proteinGoal: Double
    let waterMl: Int
    let waterGoal: Int

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerRadius = size / 2
            let innerRadius = (size * 0.7) / 2
            let lineWidth: CGFloat = 16

            ZStack {
                // Outer water ring - background
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // Outer water ring - progress
                Circle()
                    .trim(from: 0, to: CGFloat(waterPercentage))
                    .stroke(Color(red: 0.267, green: 0.627, blue: 0.933), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: waterPercentage)

                // Inner protein ring - background
                Circle()
                    .stroke(Color(red: 0.608, green: 0.820, blue: 0.455).opacity(0.15), lineWidth: lineWidth)
                    .frame(width: size * 0.7, height: size * 0.7)

                // Inner protein ring - progress
                Circle()
                    .trim(from: 0, to: CGFloat(proteinPercentage))
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.608, green: 0.820, blue: 0.455).opacity(0.75), Color(red: 0.608, green: 0.820, blue: 0.455)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: proteinPercentage)

                // Center text
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", proteinConsumed))
                        .font(.system(size: size * 0.18, weight: .bold, design: .default))
                        .foregroundColor(Color(red: 0.949, green: 0.945, blue: 0.925))
                        .monospacedDigit()

                    Text("VAN \(Int(proteinGoal))G EIWIT")
                        .font(.system(size: size * 0.048, weight: .semibold))
                        .foregroundColor(Color(red: 0.949, green: 0.945, blue: 0.925, opacity: 0.62))
                        .tracking(0.8)

                    HStack(spacing: 2) {
                        Text("\(waterMl)/\(waterGoal)ml")
                            .font(.system(size: size * 0.048, weight: .semibold))
                            .foregroundColor(Color(red: 0.267, green: 0.627, blue: 0.933))

                        Text("💧")
                            .font(.system(size: size * 0.048))
                    }
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    DualRingProgressView(
        proteinPercentage: 0.65,
        waterPercentage: 0.50,
        proteinConsumed: 78,
        proteinGoal: 120,
        waterMl: 1000,
        waterGoal: 2000
    )
    .frame(height: 300)
    .padding()
}
