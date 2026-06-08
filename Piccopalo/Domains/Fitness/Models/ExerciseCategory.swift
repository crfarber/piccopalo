import Foundation

enum ExerciseCategory: String, CaseIterable, Codable, Identifiable {
    case borst
    case rug
    case schouders
    case armen
    case benen
    case core

    var id: String { rawValue }

    var label: String {
        switch self {
        case .borst: return "Borst"
        case .rug: return "Rug"
        case .schouders: return "Schouders"
        case .armen: return "Armen"
        case .benen: return "Benen"
        case .core: return "Core"
        }
    }

    var icon: String {
        switch self {
        case .borst: return "figure.strengthtraining.traditional"
        case .rug: return "figure.rower"
        case .schouders: return "figure.arms.open"
        case .armen: return "dumbbell.fill"
        case .benen: return "figure.walk"
        case .core: return "figure.core.training"
        }
    }
}
