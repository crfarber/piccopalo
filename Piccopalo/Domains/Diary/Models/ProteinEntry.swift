import Foundation

enum ProteinEntryUnit: String, Codable {
    case grams = "g"
    case milliliters = "ml"

    var symbol: String {
        rawValue
    }
}

struct ProteinEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let sourceName: String
    let quantity: Double
    let unit: ProteinEntryUnit
    let proteinPer100: Double
    let proteinAmount: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sourceName: String,
        quantity: Double,
        unit: ProteinEntryUnit,
        proteinPer100: Double,
        proteinAmount: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sourceName = sourceName
        self.quantity = quantity
        self.unit = unit
        self.proteinPer100 = proteinPer100
        self.proteinAmount = proteinAmount
        self.createdAt = createdAt
    }
}
