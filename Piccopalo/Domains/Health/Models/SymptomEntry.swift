import Foundation

struct SymptomEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let dateIso: String
    let recordedAt: Date
    let energyLevel: Int?         // 1-5
    let focusLevel: Int?          // 1-5
    let hungerLevel: Int?         // 1-5
    let note: String?

    init(
        id: UUID = UUID(),
        dateIso: String,
        recordedAt: Date = Date(),
        energyLevel: Int? = nil,
        focusLevel: Int? = nil,
        hungerLevel: Int? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.dateIso = dateIso
        self.recordedAt = recordedAt
        self.energyLevel = energyLevel
        self.focusLevel = focusLevel
        self.hungerLevel = hungerLevel
        self.note = note
    }
}

/// Beschrijft één van de drie te loggen gevoel-dimensies en de bijbehorende emoji-schaal.
enum SymptomDimension: String, CaseIterable, Identifiable {
    case energy
    case focus
    case hunger

    var id: String { rawValue }

    var label: String {
        switch self {
        case .energy: return "Energie"
        case .focus: return "Focus"
        case .hunger: return "Honger"
        }
    }

    /// Emoji voor een niveau van 1 t/m 5 (laag naar hoog).
    func emoji(for level: Int) -> String {
        let clamped = min(max(level, 1), 5)
        switch self {
        case .energy:
            return ["😴", "🥱", "🙂", "😃", "⚡️"][clamped - 1]
        case .focus:
            return ["🌫", "😵‍💫", "🙂", "🧐", "🎯"][clamped - 1]
        case .hunger:
            return ["🙂", "😐", "😋", "😣", "🐺"][clamped - 1]
        }
    }
}
