import Foundation

struct DayRecord: Codable, Identifiable {
    var id: String { date }
    let date: String
    var weight: Double
    var activityFactor: Double
    var proteinGoal: Double
    var proteinConsumed: Double
}
