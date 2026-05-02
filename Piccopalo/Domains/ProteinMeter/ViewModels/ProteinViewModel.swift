import Foundation
import Combine

class ProteinViewModel: ObservableObject {
    @Published var activityFactor: Double = 1.2
    @Published var proteinInput: String = ""
    @Published var todayRecord: DayRecord?
    private let accountStorage = AccountStorage()

    let activityOptions: [(label: String, factor: Double)] = [
        ("Weinig beweging", 0.8),
        ("Licht actief", 1.2),
        ("Regelmatig sporten", 1.4),
        ("Intensief trainen", 1.6)
    ]

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

    init() {
        loadToday()
    }

    var accountWeight: Double {
        accountStorage.load()?.weight ?? 0
    }

    func loadToday() {
        guard let record = StorageManager.shared.loadRecord(for: today) else { return }
        todayRecord = record
        activityFactor = record.activityFactor
    }

    func addProtein() {
        applyProteinDelta(Double(proteinInput) ?? 0)
    }

    func subtractProtein() {
        let amount = Double(proteinInput) ?? 0
        guard amount > 0 else { return }
        applyProteinDelta(-amount)
    }

    private func applyProteinDelta(_ delta: Double) {
        guard delta != 0 else { return }

        let weightValue = accountWeight
        let goal = weightValue * activityFactor
        let previous = todayRecord?.proteinConsumed ?? 0
        let consumed = max(0, previous + delta)
        guard consumed != previous else { return }

        let record = DayRecord(
            date: today,
            weight: weightValue,
            activityFactor: activityFactor,
            proteinGoal: goal,
            proteinConsumed: consumed
        )
        todayRecord = record
        StorageManager.shared.saveRecord(for: today, record: record)
        proteinInput = ""
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
        StorageManager.shared.loadAllRecords()
    }
}
