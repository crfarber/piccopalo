import SwiftUI

enum TimelineEvent: Identifiable {
    case meal(ProteinEntry)
    case bloodSugar(BloodSugarEntry)
    case symptom(SymptomEntry)
    case water(WaterEntry)

    var id: String {
        switch self {
        case .meal(let e): return "meal-\(e.id.uuidString)"
        case .bloodSugar(let e): return "bs-\(e.id.uuidString)"
        case .symptom(let e): return "sym-\(e.id.uuidString)"
        case .water(let e): return "water-\(e.id.uuidString)"
        }
    }

    var timestamp: Date {
        switch self {
        case .meal(let e): return e.createdAt
        case .bloodSugar(let e): return e.recordedAt
        case .symptom(let e): return e.recordedAt
        case .water(let e): return e.createdAt
        }
    }

    var icon: String {
        switch self {
        case .meal: return "fork.knife"
        case .bloodSugar: return "drop.fill"
        case .symptom: return "face.smiling"
        case .water: return "waterbottle.fill"
        }
    }

    var title: String {
        switch self {
        case .meal(let e):
            return e.sourceName
        case .bloodSugar(let e):
            return String(format: "%.1f mmol/L", e.valueMmol)
        case .symptom:
            return "Gevoel"
        case .water(let e):
            return "\(e.milliliters) ml water"
        }
    }

    var subtitle: String {
        switch self {
        case .meal(let e):
            var parts: [String] = [String(format: "%.0fg eiwit", e.proteinAmount)]
            if e.glycemicIndex != nil {
                let category = e.glycemicCategory
                parts.append("\(category.emoji) \(category.label)")
            }
            return parts.joined(separator: " · ")
        case .bloodSugar(let e):
            return e.moment?.label ?? "Meting"
        case .symptom(let e):
            var emojis: [String] = []
            if let energy = e.energyLevel { emojis.append(SymptomDimension.energy.emoji(for: energy)) }
            if let focus = e.focusLevel { emojis.append(SymptomDimension.focus.emoji(for: focus)) }
            if let hunger = e.hungerLevel { emojis.append(SymptomDimension.hunger.emoji(for: hunger)) }
            let emojiPart = emojis.joined(separator: " ")
            if let note = e.note, !note.isEmpty {
                return emojiPart.isEmpty ? note : "\(emojiPart) · \(note)"
            }
            return emojiPart
        case .water:
            return "Hydratatie"
        }
    }

    var color: Color {
        switch self {
        case .meal(let e):
            return e.glycemicIndex != nil ? e.glycemicCategory.color : Theme.Colors.green
        case .bloodSugar: return Theme.Colors.tomato
        case .symptom: return Theme.Colors.cream
        case .water: return Theme.Colors.blue
        }
    }
}
