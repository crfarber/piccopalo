import Foundation
import Combine

@MainActor
class ProteinViewModel: ObservableObject {
    @Published var proteinInput: String = ""
    @Published var todayRecord: DayRecord?
    @Published var accountPayload: AccountData?
    @Published var waterConsumed: Double = 0
    @Published var waterGoal: Int = 2000
    @Published var waterEntries: [WaterEntry] = []

    private let diaryRepository: DiaryRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let waterRepository: WaterRepositoryProtocol
    private var accountChangeCancellable: AnyCancellable?

    var proteinGoal: Double {
        if let goalFromDay = todayRecord?.proteinGoal, goalFromDay > 0 {
            return goalFromDay
        }
        let computed = accountWeight * activityFactor
        return max(computed, 0)
    }
    var proteinConsumed: Double { todayRecord?.proteinConsumed ?? 0 }
    var remaining: Double { max(proteinGoal - proteinConsumed, 0) }
    var percentage: Double {
        guard proteinGoal > 0 else { return 0 }
        return min((proteinConsumed / proteinGoal) * 100, 100)
    }

    var waterPercentage: Double {
        guard waterGoal > 0 else { return 0 }
        return min(waterConsumed / Double(waterGoal), 1.0)
    }

    var waterRemaining: Int {
        max(waterGoal - Int(waterConsumed), 0)
    }

    func message(for percentage: Double) -> String {
        if percentage >= 100 { return "Geweldig! Doel gehaald." }
        if percentage >= 75 { return "Bijna daar, nog even doorzetten." }
        if percentage >= 40 { return "Goede start, blijf consequent." }
        return "Begin met je eerste eiwitinname van vandaag." }

    var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    var accountWeight: Double { accountPayload?.weight ?? 0 }
    var activityFactor: Double { accountPayload?.activityFactor ?? 1.2 }

    init(diaryRepository: DiaryRepositoryProtocol, userProfileRepository: UserProfileRepositoryProtocol, waterRepository: WaterRepositoryProtocol) {
        self.diaryRepository = diaryRepository
        self.userProfileRepository = userProfileRepository
        self.waterRepository = waterRepository
        Task { await refresh() }
        accountChangeCancellable = NotificationCenter.default.publisher(for: .piccopaloAccountDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in Task { await self?.refresh() } }
    }

    func refresh() async {
        async let day = diaryRepository.day(for: today)
        async let account = userProfileRepository.loadAccount()
        todayRecord = await day
        accountPayload = await account
        waterGoal = (await account)?.waterGoalMl ?? 2000
        await loadWaterData()
    }

    func loadToday() {
        Task { await refresh() }
    }

    func record(for dateISO: String) async -> DayRecord? {
        await diaryRepository.day(for: dateISO)
    }

    func waterEntries(for dateISO: String) async -> [WaterEntry] {
        (try? await waterRepository.waterEntriesForDay(dateISO)) ?? []
    }

    func allRecords() async -> [DayRecord] {
        await diaryRepository.allDaysSorted()
    }

    func saveDayRecord(_ record: DayRecord) {
        Task {
            await diaryRepository.save(record)
            if record.date == today { await refresh() }
        }
    }

    func addProtein() {
        let amount = Double(proteinInput) ?? 0
        guard amount > 0 else { return }
        let entry = ProteinEntry(sourceName: "Handmatig", quantity: amount, unit: .grams, proteinPer100: 100, proteinAmount: amount)
        applyEntry(entry)
        proteinInput = ""
    }

    func addProtein(source: ProteinSource, quantity: Double) {
        guard quantity > 0 else { return }
        let amount = (quantity / 100) * source.proteinPer100g
        guard amount > 0 else { return }
        let unit: ProteinEntryUnit = source.unit == .milliliters ? .milliliters : .grams
        let entry = ProteinEntry(sourceName: source.name, quantity: quantity, unit: unit, proteinPer100: source.proteinPer100g, proteinAmount: amount)
        applyEntry(entry)
    }

    func addProtein(source: ProteinSource, quantity: Double, to dateISO: String) async {
        guard quantity > 0 else { return }
        let amount = (quantity / 100) * source.proteinPer100g
        guard amount > 0 else { return }
        let unit: ProteinEntryUnit = source.unit == .milliliters ? .milliliters : .grams
        let entry = ProteinEntry(sourceName: source.name, quantity: quantity, unit: unit, proteinPer100: source.proteinPer100g, proteinAmount: amount)
        await appendProteinEntry(entry, to: dateISO)
    }

    /// Voegt een gescand product toe inclusief glycemische / voedingsdata voor de gekozen portie.
    func addScannedProduct(_ product: FoodProduct, quantity: Double) {
        guard quantity > 0 else { return }
        let entry = scannedProductEntry(product, quantity: quantity)
        applyEntry(entry)
    }

    func addScannedProduct(_ product: FoodProduct, quantity: Double, to dateISO: String) async {
        guard quantity > 0 else { return }
        let entry = scannedProductEntry(product, quantity: quantity)
        await appendProteinEntry(entry, to: dateISO)
    }

    private func scannedProductEntry(_ product: FoodProduct, quantity: Double) -> ProteinEntry {
        let amount = (quantity / 100) * product.proteinPer100g
        let factor = quantity / 100
        return ProteinEntry(
            sourceName: product.name,
            quantity: quantity,
            unit: .grams,
            proteinPer100: product.proteinPer100g,
            proteinAmount: amount,
            carbsGrams: product.carbsPer100g.map { $0 * factor },
            fiberGrams: product.fiberPer100g.map { $0 * factor },
            fatGrams: product.fatPer100g.map { $0 * factor },
            glycemicIndex: product.glycemicIndex,
            glycemicLoad: product.glycemicLoad(forPortionGrams: quantity)
        )
    }

    private func appendProteinEntry(_ entry: ProteinEntry, to dateISO: String) async {
        var record = await ensureDayRecord(for: dateISO)
        record.entries.append(entry)
        record.proteinConsumed += entry.proteinAmount
        await diaryRepository.save(record)
        if dateISO == today {
            todayRecord = record
        }
    }

    func subtractProtein() {
        let amount = Double(proteinInput) ?? 0
        guard amount > 0 else { return }
        let previous = currentDayRecord().proteinConsumed
        let applied = min(amount, previous)
        guard applied > 0 else { return }
        let entry = ProteinEntry(sourceName: "Correctie", quantity: applied, unit: .grams, proteinPer100: 100, proteinAmount: -applied)
        applyEntry(entry)
        proteinInput = ""
    }

    private func currentDayRecord() -> DayRecord {
        let existing = todayRecord
        let factorForDay = existing?.activityFactor ?? activityFactor
        let goalForDay = existing?.proteinGoal ?? (accountWeight * factorForDay)
        return DayRecord(
            date: today,
            weight: accountWeight,
            activityFactor: factorForDay,
            proteinGoal: goalForDay,
            proteinConsumed: existing?.proteinConsumed ?? 0,
            entries: existing?.entries ?? []
        )
    }

    private func applyEntry(_ entry: ProteinEntry) {
        var record = currentDayRecord()
        record.entries.append(entry)
        record = DayRecord(
            date: record.date,
            weight: record.weight,
            activityFactor: record.activityFactor,
            proteinGoal: record.proteinGoal,
            proteinConsumed: record.proteinConsumed + entry.proteinAmount,
            entries: record.entries
        )
        todayRecord = record
        saveDayRecord(record)
    }

    // MARK: - Water Management

    func loadWaterData() async {
        do {
            waterEntries = try await waterRepository.waterEntriesForDay(today)
            waterConsumed = Double(try await waterRepository.totalWaterForDay(today))
        } catch {
            print("Error loading water data: \(error)")
        }
    }

    func addWaterEntry(milliliters: Int) async throws {
        try await addWaterEntry(milliliters: milliliters, to: today)
    }

    func addWaterEntry(milliliters: Int, to dateISO: String) async throws {
        let dayRecord = await ensureDayRecord(for: dateISO)
        let entry = try await waterRepository.addWaterEntry(
            dayRecordId: UUID(),
            milliliters: milliliters,
            dateISO: dateISO,
            entryId: nil,
            createdAt: nil
        )

        if dateISO == today {
            waterEntries.append(entry)
            waterConsumed += Double(milliliters)
        }

        var updatedRecord = dayRecord
        let total = try await waterRepository.totalWaterForDay(dateISO)
        updatedRecord.waterConsumed = Double(total)
        await diaryRepository.save(updatedRecord)
        if dateISO == today {
            todayRecord = updatedRecord
        }
    }

    func removeWaterEntry(_ entry: WaterEntry) async throws {
        try await removeWaterEntry(entry, from: today)
    }

    func removeWaterEntry(_ entry: WaterEntry, from dateISO: String) async throws {
        try await waterRepository.deleteWaterEntry(entry.id)

        if dateISO == today {
            waterEntries.removeAll { $0.id == entry.id }
            waterConsumed = max(waterConsumed - Double(entry.milliliters), 0)
        }

        if var record = await diaryRepository.day(for: dateISO) {
            let total = try await waterRepository.totalWaterForDay(dateISO)
            record.waterConsumed = Double(total)
            await diaryRepository.save(record)
            if dateISO == today {
                todayRecord = record
            }
        }
    }

    func removeProteinEntry(_ entry: ProteinEntry, from dateISO: String) async {
        guard var record = await diaryRepository.day(for: dateISO) else { return }
        guard record.entries.contains(where: { $0.id == entry.id }) else { return }

        record.entries.removeAll { $0.id == entry.id }
        record.proteinConsumed = record.entries.reduce(0) { $0 + $1.proteinAmount }
        await diaryRepository.save(record)

        if dateISO == today {
            todayRecord = record
        }
    }

    func addManualProtein(grams: Double, to dateISO: String, sourceName: String = "Handmatig") async {
        guard grams > 0 else { return }
        var record = await ensureDayRecord(for: dateISO)
        let entry = ProteinEntry(
            sourceName: sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Handmatig" : sourceName,
            quantity: grams,
            unit: .grams,
            proteinPer100: 100,
            proteinAmount: grams
        )
        record.entries.append(entry)
        record.proteinConsumed += grams
        await diaryRepository.save(record)
        if dateISO == today {
            todayRecord = record
        }
    }

    func updateProteinEntry(
        id: UUID,
        in dateISO: String,
        sourceName: String,
        quantity: Double
    ) async {
        guard quantity > 0,
              var record = await diaryRepository.day(for: dateISO),
              let index = record.entries.firstIndex(where: { $0.id == id }) else { return }

        let old = record.entries[index]
        let ratio = old.quantity > 0 ? quantity / old.quantity : 1
        let newProteinAmount = (quantity / 100) * old.proteinPer100
        let trimmedName = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)

        let updated = ProteinEntry(
            id: old.id,
            sourceName: trimmedName.isEmpty ? old.sourceName : trimmedName,
            quantity: quantity,
            unit: old.unit,
            proteinPer100: old.proteinPer100,
            proteinAmount: newProteinAmount,
            createdAt: old.createdAt,
            carbsGrams: old.carbsGrams.map { $0 * ratio },
            fiberGrams: old.fiberGrams.map { $0 * ratio },
            fatGrams: old.fatGrams.map { $0 * ratio },
            glycemicIndex: old.glycemicIndex,
            glycemicLoad: old.glycemicLoad.map { $0 * ratio }
        )

        record.entries[index] = updated
        record.proteinConsumed = record.entries.reduce(0) { $0 + $1.proteinAmount }
        await diaryRepository.save(record)
        if dateISO == today {
            todayRecord = record
        }
    }

    func updateWaterEntry(_ entry: WaterEntry, milliliters: Int, on dateISO: String) async throws {
        guard milliliters > 0 else { return }
        try await waterRepository.deleteWaterEntry(entry.id)
        _ = try await waterRepository.addWaterEntry(
            dayRecordId: entry.dayRecordId,
            milliliters: milliliters,
            dateISO: dateISO,
            entryId: entry.id,
            createdAt: entry.createdAt
        )

        if dateISO == today {
            if let idx = waterEntries.firstIndex(where: { $0.id == entry.id }) {
                waterEntries[idx] = WaterEntry(
                    id: entry.id,
                    dayRecordId: entry.dayRecordId,
                    milliliters: milliliters,
                    createdAt: entry.createdAt
                )
            }
            waterConsumed = max(waterConsumed - Double(entry.milliliters) + Double(milliliters), 0)
        }

        if var record = await diaryRepository.day(for: dateISO) {
            let total = try await waterRepository.totalWaterForDay(dateISO)
            record.waterConsumed = Double(total)
            await diaryRepository.save(record)
            if dateISO == today {
                todayRecord = record
            }
        }
    }

    private func ensureDayRecord(for dateISO: String) async -> DayRecord {
        if let existing = await diaryRepository.day(for: dateISO) {
            return existing
        }
        let factor = await diaryRepository.day(for: today)?.activityFactor ?? activityFactor
        let record = DayRecord(
            date: dateISO,
            weight: accountWeight,
            activityFactor: factor,
            proteinGoal: accountWeight * factor,
            proteinConsumed: 0
        )
        await diaryRepository.save(record)
        if dateISO == today {
            todayRecord = record
        }
        return record
    }
}