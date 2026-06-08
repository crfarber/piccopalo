import SwiftUI

enum GICategory {
    case low, medium, high, unknown

    /// Bepaalt de categorie op basis van een GI-waarde (0-100).
    init(glycemicIndex: Int?) {
        guard let gi = glycemicIndex else {
            self = .unknown
            return
        }
        switch gi {
        case 0...55: self = .low
        case 56...70: self = .medium
        default: self = .high
        }
    }

    var label: String {
        switch self {
        case .low: return "Laag GI"
        case .medium: return "Medium GI"
        case .high: return "Hoog GI"
        case .unknown: return "GI onbekend"
        }
    }

    var color: Color {
        switch self {
        case .low: return Theme.Colors.green
        case .medium: return Theme.Colors.warning
        case .high: return Theme.Colors.tomato
        case .unknown: return Theme.Colors.textDim
        }
    }

    var emoji: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟠"
        case .high: return "🔴"
        case .unknown: return "⚪️"
        }
    }
}

/// Berekent de glycemische lading: GL = (GI x koolhydraten) / 100.
func glycemicLoad(glycemicIndex: Int?, carbsGrams: Double?) -> Double? {
    guard let gi = glycemicIndex, let carbs = carbsGrams else { return nil }
    return (Double(gi) * carbs) / 100.0
}
