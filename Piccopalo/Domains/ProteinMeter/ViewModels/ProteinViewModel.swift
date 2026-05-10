import Foundation
import Combine

class ProteinViewModel: ObservableObject {
    @Published var proteinInput: String = ""
    @Published var todayRecord: DayRecord?

    private let diaryRepository: DiaryRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private var accountChangeCancellable: AnyCancellable?

    var proteinGoal: Double {
        accountWeight * activityFactor
    }

    var proteinConsumed: Double {
        todayRecord?.proteinConsumed ?? 0
    }

    var remaining: Double {
        max(proteinGoal - proteinConsumed, 0)
    }

    var percentage: Double {
        guard proteinGoal > 0 else { return 0 }
        return min((proteinConsumed / proteinGoal) * 100, 100)
    }

    var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    init(diaryRepository: DiaryRepositoryProtocol, userProfileRepository: UserProfileRepositoryProtocol) {
        self.diaryRepository = diaryRepository
        self.userProfileRepository = userProfileRepository
        loadToday()
        accountChangeCancellable = NotificationCenter.default.publisher(for: .piccopaloAccountDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    var accountWeight: Double {
        accountPayload?.weight ?? 0
    }

    var activityFactor: Double {
        accountPayload?.activityFactor ?? 1.2
    }

    private var accountPayload: AccountData? {
        userProfileRepository.loadAccount()
    }

    func loadToday() {
        todayRecord = diaryRepository.day(for: today)
    }

    /// Dagrecord voor een ISO-datum (geschiedenis / weekstrip).
    func record(for dateISO: String) -> DayRecord? {
        diaryRepository.day(for: dateISO)
    }

    /// Persisteert een volledig dagrecord (detailpagina).
    func saveDayRecord(_ record: DayRecord) {
        diaryRepository.save(record)
        if record.date == today {
            loadToday()
        }
    }

    func addProtein() {
        let amount = Double(proteinInput) ?? 0
        guard amount > 0 else { return }

        let entry = ProteinEntry(
            sourceName: "Handmatig",
            quantity: amount,
            unit: .grams,
            proteinPer100: 100,
            proteinAmount: amount
        )
        applyEntry(entry)
        proteinInput = ""
    }

    func addProtein(source: ProteinSource, quantity: Double) {
        guard quantity > 0 else { return }
        let amount = (quantity / 100) * source.proteinPer100g
        guard amount > 0 else { return }

        let unit: ProteinEntryUnit = source.unit == .milliliters ? .milliliters : .grams
        let entry = ProteinEntry(
            sourceName: source.name,
            quantity: quantity,
            unit: unit,
            proteinPer100: source.proteinPer100g,
            proteinAmount: amount
        )
        applyEntry(entry)
    }

    func subtractProtein() {
        let amount = Double(proteinInput) ?? 0
        guard amount > 0 else { return }

        let previous = currentDayRecord().proteinConsumed
        let applied = min(amount, previous)
        guard applied > 0 else { return }

        let entry = ProteinEntry(
            sourceName: "Correctie",
            quantity: applied,
            unit: .grams,
            proteinPer100: 100,
            proteinAmount: -applied
        )
        applyEntry(entry)
        proteinInput = ""
    }

    private func currentDayRecord() -> DayRecord {
        let weightValue = accountWeight
        let existing = todayRecord ?? diaryRepository.day(for: today)
        let factorForDay = existing?.activityFactor ?? activityFactor
        let goal = weightValue * factorForDay
        return DayRecord(
            date: today,
            weight: weightValue,
            activityFactor: factorForDay,
            proteinGoal: goal,
            proteinConsumed: existing?.proteinConsumed ?? 0,
            entries: existing?.entries ?? []
        )
    }

    private func applyEntry(_ entry: ProteinEntry) {
        var record = currentDayRecord()
        record.entries.insert(entry, at: 0)
        record.proteinConsumed = max(0, record.proteinConsumed + entry.proteinAmount)

        todayRecord = record
        diaryRepository.save(record)
    }

    func message(for percentage: Double) -> String {
        switch percentage {
        case ..<30:   return "Andiamo! Je bent net begonnen! 🚀"
        case 30..<60: return "Bravo amico, je bent op weg! 💪"
        case 60..<90: return "Fantastico! Bijna daar! 🔥"
        default:      return "Perfetto! Je hebt je doel gehaald! 🎉"
        }
    }

    func allRecords() -> [DayRecord] {
        diaryRepository.allDaysSorted()
    }
}
