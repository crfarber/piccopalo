import Foundation
import Combine

@MainActor
class ProteinViewModel: ObservableObject {
    @Published var proteinInput: String = ""
    @Published var todayRecord: DayRecord?
    @Published var accountPayload: AccountData?

    private let diaryRepository: DiaryRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private var accountChangeCancellable: AnyCancellable?

    var proteinGoal: Double { accountWeight * activityFactor }
    var proteinConsumed: Double { todayRecord?.proteinConsumed ?? 0 }
    var remaining: Double { max(proteinGoal - proteinConsumed, 0) }
    var percentage: Double {
        guard proteinGoal > 0 else { return 0 }
        return min((proteinConsumed / proteinGoal) * 100, 100)
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

    init(diaryRepository: DiaryRepositoryProtocol, userProfileRepository: UserProfileRepositoryProtocol) {
        self.diaryRepository = diaryRepository
        self.userProfileRepository = userProfileRepository
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
        return DayRecord(
            date: today,
            weight: accountWeight,
            activityFactor: factorForDay,
            proteinGoal: accountWeight * factorForDay,
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
}