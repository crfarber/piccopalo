import Foundation

enum BSMoment: String, Codable, CaseIterable, Identifiable {
    case nuchter
    case voorEten = "voor_eten"
    case naEten = "na_eten"
    case nacht
    case willekeurig

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nuchter: return "Nuchter"
        case .voorEten: return "Vóór het eten"
        case .naEten: return "Na het eten"
        case .nacht: return "Nacht"
        case .willekeurig: return "Zomaar"
        }
    }

    var icon: String {
        switch self {
        case .nuchter: return "sunrise"
        case .voorEten: return "fork.knife"
        case .naEten: return "clock.arrow.circlepath"
        case .nacht: return "moon.stars"
        case .willekeurig: return "circle.dotted"
        }
    }
}

struct BloodSugarEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let dateIso: String          // "2024-06-07"
    let recordedAt: Date
    let valueMmol: Double         // mmol/L
    let moment: BSMoment?
    let note: String?

    init(
        id: UUID = UUID(),
        dateIso: String,
        recordedAt: Date = Date(),
        valueMmol: Double,
        moment: BSMoment? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.dateIso = dateIso
        self.recordedAt = recordedAt
        self.valueMmol = valueMmol
        self.moment = moment
        self.note = note
    }
}
