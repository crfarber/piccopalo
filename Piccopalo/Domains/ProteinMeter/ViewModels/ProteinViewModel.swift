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
        let dayRecord: DayRecord
        if let existing = todayRecord {
            dayRecord = existing
        } else {
            // Create today's record on first water action, then continue with insert.
            let record = currentDayRecord()
            await diaryRepository.save(record)
            todayRecord = record
            dayRecord = record
        }

        let entry = try await waterRepository.addWaterEntry(dayRecordId: UUID(), milliliters: milliliters)
        waterEntries.append(entry)
        waterConsumed += Double(milliliters)

        // Update the day record
        var updatedRecord = dayRecord
        updatedRecord.waterConsumed = waterConsumed
        todayRecord = updatedRecord
        await diaryRepository.save(updatedRecord)
    }

    func removeWaterEntry(_ entry: WaterEntry) async throws {
        try await waterRepository.deleteWaterEntry(entry.id)
        waterEntries.removeAll { $0.id == entry.id }
        waterConsumed = max(waterConsumed - Double(entry.milliliters), 0)

        // Update the day record
        if var updatedRecord = todayRecord {
            updatedRecord.waterConsumed = waterConsumed
            todayRecord = updatedRecord
            await diaryRepository.save(updatedRecord)
        }
    }
}