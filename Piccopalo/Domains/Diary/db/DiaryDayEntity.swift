import Foundation
import SwiftData

@Model
final class DiaryDayEntity {
    @Attribute(.unique) var dateISO: String
    var weight: Double
    var activityFactor: Double
    var proteinGoal: Double
    var proteinConsumed: Double
    @Relationship(deleteRule: .cascade, inverse: \DiaryProteinEntryEntity.day)
    var entries: [DiaryProteinEntryEntity] = []

    init(dateISO: String, weight: Double, activityFactor: Double, proteinGoal: Double, proteinConsumed: Double) {
        self.dateISO = dateISO
        self.weight = weight
        self.activityFactor = activityFactor
        self.proteinGoal = proteinGoal
        self.proteinConsumed = proteinConsumed
    }

    convenience init(from record: DayRecord) {
        self.init(
            dateISO: record.date,
            weight: record.weight,
            activityFactor: record.activityFactor,
            proteinGoal: record.proteinGoal,
            proteinConsumed: record.proteinConsumed
        )
    }

    func apply(from record: DayRecord) {
        weight = record.weight
        activityFactor = record.activityFactor
        proteinGoal = record.proteinGoal
        proteinConsumed = record.proteinConsumed
    }

    var asDayRecord: DayRecord {
        DayRecord(
            date: dateISO,
            weight: weight,
            activityFactor: activityFactor,
            proteinGoal: proteinGoal,
            proteinConsumed: proteinConsumed,
            entries: entries
                .map(\.asProteinEntry)
                .sorted(by: { $0.createdAt > $1.createdAt })
        )
    }
}
