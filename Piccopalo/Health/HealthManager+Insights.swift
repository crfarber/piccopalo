import HealthKit
import Foundation

extension HealthManager {
    /// Fetches the per-day step count over a date range (for weekly insights).
    /// Returns a dictionary keyed by ISO date string ("yyyy-MM-dd").
    func fetchDailyStepCounts(from start: Date, to end: Date) async -> [String: Int] {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return [:] }

        let store = HKHealthStore()
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        let endOfRange = calendar.startOfDay(for: end)
        let interval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(
            withStart: anchor,
            end: calendar.date(byAdding: .day, value: 1, to: endOfRange) ?? end
        )

        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.timeZone = TimeZone.current

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                var counts: [String: Int] = [:]
                results?.enumerateStatistics(from: anchor, to: endOfRange) { statistics, _ in
                    let value = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    let key = isoFormatter.string(from: statistics.startDate)
                    counts[key] = Int(value)
                }
                continuation.resume(returning: counts)
            }

            store.execute(query)
        }
    }
}
