import Foundation
import SwiftData

@Model
final class DiaryProteinEntryEntity {
    @Attribute(.unique) var entryID: UUID
    var sourceName: String
    var quantity: Double
    var unitRaw: String
    var proteinPer100: Double
    var proteinAmount: Double
    var createdAt: Date

    var day: DiaryDayEntity?

    init(
        entryID: UUID,
        sourceName: String,
        quantity: Double,
        unitRaw: String,
        proteinPer100: Double,
        proteinAmount: Double,
        createdAt: Date,
        day: DiaryDayEntity? = nil
    ) {
        self.entryID = entryID
        self.sourceName = sourceName
        self.quantity = quantity
        self.unitRaw = unitRaw
        self.proteinPer100 = proteinPer100
        self.proteinAmount = proteinAmount
        self.createdAt = createdAt
        self.day = day
    }

    convenience init(from entry: ProteinEntry, day: DiaryDayEntity? = nil) {
        self.init(
            entryID: entry.id,
            sourceName: entry.sourceName,
            quantity: entry.quantity,
            unitRaw: entry.unit.rawValue,
            proteinPer100: entry.proteinPer100,
            proteinAmount: entry.proteinAmount,
            createdAt: entry.createdAt,
            day: day
        )
    }

    var asProteinEntry: ProteinEntry {
        ProteinEntry(
            id: entryID,
            sourceName: sourceName,
            quantity: quantity,
            unit: ProteinEntryUnit(rawValue: unitRaw) ?? .grams,
            proteinPer100: proteinPer100,
            proteinAmount: proteinAmount,
            createdAt: createdAt
        )
    }
}
