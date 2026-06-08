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

    // Glycemische / voedingsdata (optioneel, alleen gevuld via barcode scan).
    let carbsGrams: Double?
    let fiberGrams: Double?
    let fatGrams: Double?
    let glycemicIndex: Int?
    let glycemicLoad: Double?

    init(
        id: UUID = UUID(),
        sourceName: String,
        quantity: Double,
        unit: ProteinEntryUnit,
        proteinPer100: Double,
        proteinAmount: Double,
        createdAt: Date = Date(),
        carbsGrams: Double? = nil,
        fiberGrams: Double? = nil,
        fatGrams: Double? = nil,
        glycemicIndex: Int? = nil,
        glycemicLoad: Double? = nil
    ) {
        self.id = id
        self.sourceName = sourceName
        self.quantity = quantity
        self.unit = unit
        self.proteinPer100 = proteinPer100
        self.proteinAmount = proteinAmount
        self.createdAt = createdAt
        self.carbsGrams = carbsGrams
        self.fiberGrams = fiberGrams
        self.fatGrams = fatGrams
        self.glycemicIndex = glycemicIndex
        self.glycemicLoad = glycemicLoad
    }

    var glycemicCategory: GICategory {
        GICategory(glycemicIndex: glycemicIndex)
    }
}
