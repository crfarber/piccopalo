import Foundation
import Combine

@MainActor
class HealthViewModel: ObservableObject {
    @Published var todaysReadings: [BloodSugarEntry] = []
    @Published var todaysSymptoms: [SymptomEntry] = []
    @Published var errorMessage: String?

    private let bloodSugarRepository: BloodSugarRepositoryProtocol
    private let symptomRepository: SymptomRepositoryProtocol

    init(
        bloodSugarRepository: BloodSugarRepositoryProtocol,
        symptomRepository: SymptomRepositoryProtocol
    ) {
        self.bloodSugarRepository = bloodSugarRepository
        self.symptomRepository = symptomRepository
        Task { await loadToday() }
    }

    var today: String {
        Self.isoFormatter.string(from: Date())
    }

    static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - Blood sugar

    func loadToday() async {
        await loadReadings(for: today)
        await loadSymptoms(for: today)
    }

    func loadReadings(for dateIso: String) async {
        do {
            todaysReadings = try await bloodSugarRepository.readings(for: dateIso)
        } catch {
            print("Error loading blood sugar readings: \(error)")
        }
    }

    func readings(for dateIso: String) async -> [BloodSugarEntry] {
        do {
            return try await bloodSugarRepository.readings(for: dateIso)
        } catch {
            print("Error fetching blood sugar readings: \(error)")
            return []
        }
    }

    func saveBloodSugar(valueMmol: Double, moment: BSMoment, note: String?, dateIso: String? = nil) async {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetDate = dateIso ?? today
        let entry = BloodSugarEntry(
            dateIso: targetDate,
            recordedAt: Date(),
            valueMmol: valueMmol,
            moment: moment,
            note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil
        )
        do {
            try await bloodSugarRepository.save(entry)
            if targetDate == today {
                await loadToday()
            }
        } catch {
            errorMessage = "Bloedsuiker opslaan mislukt: \(error.localizedDescription)"
            print("Error saving blood sugar reading: \(error)")
        }
    }

    func updateBloodSugar(
        _ entry: BloodSugarEntry,
        valueMmol: Double,
        moment: BSMoment,
        note: String?
    ) async {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = BloodSugarEntry(
            id: entry.id,
            dateIso: entry.dateIso,
            recordedAt: entry.recordedAt,
            valueMmol: valueMmol,
            moment: moment,
            note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil
        )
        do {
            try await bloodSugarRepository.delete(entry.id)
            try await bloodSugarRepository.save(updated)
            if entry.dateIso == today {
                await loadReadings(for: today)
            }
        } catch {
            print("Error updating blood sugar reading: \(error)")
        }
    }

    func deleteBloodSugar(_ entry: BloodSugarEntry) async {
        do {
            try await bloodSugarRepository.delete(entry.id)
            todaysReadings.removeAll { $0.id == entry.id }
        } catch {
            print("Error deleting blood sugar reading: \(error)")
        }
    }

    // MARK: - Symptoms

    func loadSymptoms(for dateIso: String) async {
        do {
            todaysSymptoms = try await symptomRepository.entries(for: dateIso)
        } catch {
            print("Error loading symptom entries: \(error)")
        }
    }

    func symptoms(for dateIso: String) async -> [SymptomEntry] {
        do {
            return try await symptomRepository.entries(for: dateIso)
        } catch {
            print("Error fetching symptom entries: \(error)")
            return []
        }
    }

    func saveSymptom(energy: Int?, focus: Int?, hunger: Int?, note: String?, dateIso: String? = nil) async {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetDate = dateIso ?? today
        let entry = SymptomEntry(
            dateIso: targetDate,
            recordedAt: Date(),
            energyLevel: energy,
            focusLevel: focus,
            hungerLevel: hunger,
            note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil
        )
        do {
            try await symptomRepository.save(entry)
            if targetDate == today {
                await loadSymptoms(for: today)
            }
        } catch {
            errorMessage = "Gevoel opslaan mislukt: \(error.localizedDescription)"
            print("Error saving symptom entry: \(error)")
        }
    }

    func updateSymptom(
        _ entry: SymptomEntry,
        energy: Int?,
        focus: Int?,
        hunger: Int?,
        note: String?
    ) async {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = SymptomEntry(
            id: entry.id,
            dateIso: entry.dateIso,
            recordedAt: entry.recordedAt,
            energyLevel: energy,
            focusLevel: focus,
            hungerLevel: hunger,
            note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil
        )
        do {
            try await symptomRepository.delete(entry.id)
            try await symptomRepository.save(updated)
            if entry.dateIso == today {
                await loadSymptoms(for: today)
            }
        } catch {
            print("Error updating symptom entry: \(error)")
        }
    }

    func deleteSymptom(_ entry: SymptomEntry) async {
        do {
            try await symptomRepository.delete(entry.id)
            todaysSymptoms.removeAll { $0.id == entry.id }
        } catch {
            print("Error deleting symptom entry: \(error)")
        }
    }

    // MARK: - Weekly insights

    /// Haalt de bloedsuikermetingen van de afgelopen 7 dagen op en berekent lokaal de inzichten.
    func weeklyInsight(meals: [ProteinEntry], stepCounts: [String: Int]) async -> WeeklyInsight {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return .empty
        }

        let startIso = Self.isoFormatter.string(from: weekStart)
        let endIso = Self.isoFormatter.string(from: today)

        let readings: [BloodSugarEntry]
        do {
            readings = try await bloodSugarRepository.readings(from: startIso, to: endIso)
        } catch {
            print("Error loading weekly blood sugar readings: \(error)")
            return .empty
        }

        return Self.calculateWeeklyInsights(bsReadings: readings, meals: meals, stepCounts: stepCounts)
    }

    /// Pure berekening — geen netwerk, geen side effects. Goed testbaar.
    static func calculateWeeklyInsights(
        bsReadings: [BloodSugarEntry],
        meals: [ProteinEntry],
        stepCounts: [String: Int]
    ) -> WeeklyInsight {
        let bsValues = bsReadings.map { $0.valueMmol }

        // GI-drempels: hoog GI = >70, laag GI = <=55.
        let highGIMeals = meals.filter { ($0.glycemicIndex ?? 0) > 70 }
        let lowGIMeals = meals.filter { meal in
            guard let gi = meal.glycemicIndex else { return false }
            return gi <= 55
        }

        let bsAfterHighGI = bsChangesAfterMeals(meals: highGIMeals, bsReadings: bsReadings)
        let bsAfterLowGI = bsChangesAfterMeals(meals: lowGIMeals, bsReadings: bsReadings)

        // Activiteit: actief = >8000 stappen, rustig = <5000 stappen.
        let activeDates = Set(stepCounts.filter { $0.value > 8000 }.map { $0.key })
        let quietDates = Set(stepCounts.filter { $0.value < 5000 }.map { $0.key })

        let bsActiveDay = bsReadings.filter { activeDates.contains($0.dateIso) }.map { $0.valueMmol }
        let bsQuietDay = bsReadings.filter { quietDates.contains($0.dateIso) }.map { $0.valueMmol }

        // Gemiddelde koolhydraten per dag (alleen dagen met geregistreerde KH).
        let carbsByDay = Dictionary(grouping: meals.filter { $0.carbsGrams != nil }) { meal -> String in
            Self.isoFormatter.string(from: meal.createdAt)
        }
        let dailyCarbTotals = carbsByDay.values.map { entries in
            entries.reduce(0) { $0 + ($1.carbsGrams ?? 0) }
        }

        return WeeklyInsight(
            avgDailyBS: bsValues.average(),
            minBS: bsValues.min(),
            maxBS: bsValues.max(),
            bsDataPoints: bsReadings.count,
            avgBSChangeAfterHighGI: bsAfterHighGI.average(),
            highGIDataPoints: bsAfterHighGI.count,
            avgBSChangeAfterLowGI: bsAfterLowGI.average(),
            lowGIDataPoints: bsAfterLowGI.count,
            avgBSHighActivity: bsActiveDay.average(),
            avgBSLowActivity: bsQuietDay.average(),
            activityDataAvailable: !stepCounts.isEmpty,
            avgDailyCarbs: dailyCarbTotals.average()
        )
    }

    /// Berekent de BS-stijging (piek - baseline) binnen een venster na elke maaltijd.
    private static func bsChangesAfterMeals(
        meals: [ProteinEntry],
        bsReadings: [BloodSugarEntry],
        windowHours: Double = 3.0
    ) -> [Double] {
        var changes: [Double] = []

        for meal in meals {
            let mealTime = meal.createdAt
            let windowEnd = mealTime.addingTimeInterval(windowHours * 3600)
            let bsInWindow = bsReadings.filter {
                $0.recordedAt > mealTime && $0.recordedAt <= windowEnd
            }

            // Baseline: BS vlak vóór de maaltijd (binnen 30 min).
            let baselineWindow = mealTime.addingTimeInterval(-1800)
            let baseline = bsReadings
                .filter { $0.recordedAt >= baselineWindow && $0.recordedAt <= mealTime }
                .map { $0.valueMmol }
                .average()

            if let baseline, let peakBS = bsInWindow.map({ $0.valueMmol }).max() {
                changes.append(peakBS - baseline)
            }
        }
        return changes
    }
}
