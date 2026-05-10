import Foundation
import SwiftData

@MainActor
final class SwiftDataDiaryRepository: DiaryRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func day(for dateISO: String) -> DayRecord? {
        let target = dateISO
        let descriptor = FetchDescriptor<DiaryDayEntity>(
            predicate: #Predicate { $0.dateISO == target }
        )
        guard let entity = try? modelContext.fetch(descriptor).first else { return nil }
        return normalizeLegacyEntryIfNeeded(entity.asDayRecord)
    }

    func save(_ record: DayRecord) {
        let target = record.date
        let descriptor = FetchDescriptor<DiaryDayEntity>(
            predicate: #Predicate { $0.dateISO == target }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.apply(from: record)
            replaceEntries(in: existing, with: record.entries)
        } else {
            let entity = DiaryDayEntity(from: record)
            modelContext.insert(entity)
            replaceEntries(in: entity, with: record.entries)
        }
        try? modelContext.save()
    }

    func allDaysSorted() -> [DayRecord] {
        let descriptor = FetchDescriptor<DiaryDayEntity>(
            sortBy: [SortDescriptor(\.dateISO, order: .reverse)]
        )
        guard let entities = try? modelContext.fetch(descriptor) else { return [] }
        return entities.map { normalizeLegacyEntryIfNeeded($0.asDayRecord) }
    }

    private func replaceEntries(in day: DiaryDayEntity, with entries: [ProteinEntry]) {
        for entry in day.entries {
            modelContext.delete(entry)
        }
        day.entries.removeAll(keepingCapacity: true)

        for entry in entries {
            let entity = DiaryProteinEntryEntity(from: entry, day: day)
            day.entries.append(entity)
            modelContext.insert(entity)
        }
    }

    private func normalizeLegacyEntryIfNeeded(_ record: DayRecord) -> DayRecord {
        guard record.entries.isEmpty, record.proteinConsumed > 0 else { return record }

        var patched = record
        patched.entries = [
            ProteinEntry(
                sourceName: "Legacy total",
                quantity: record.proteinConsumed,
                unit: .grams,
                proteinPer100: 100,
                proteinAmount: record.proteinConsumed
            )
        ]
        return patched
    }
}
