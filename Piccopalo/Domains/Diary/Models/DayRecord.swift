import Foundation

struct DayRecord: Codable, Identifiable {
    var id: String { date }
    let date: String
    var weight: Double
    var activityFactor: Double
    var proteinGoal: Double
    var proteinConsumed: Double
    var entries: [ProteinEntry] = []

    enum CodingKeys: String, CodingKey {
        case date
        case weight
        case activityFactor
        case proteinGoal
        case proteinConsumed
        case entries
    }

    init(
        date: String,
        weight: Double,
        activityFactor: Double,
        proteinGoal: Double,
        proteinConsumed: Double,
        entries: [ProteinEntry] = []
    ) {
        self.date = date
        self.weight = weight
        self.activityFactor = activityFactor
        self.proteinGoal = proteinGoal
        self.proteinConsumed = proteinConsumed
        self.entries = entries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        weight = try container.decode(Double.self, forKey: .weight)
        activityFactor = try container.decode(Double.self, forKey: .activityFactor)
        proteinGoal = try container.decode(Double.self, forKey: .proteinGoal)
        proteinConsumed = try container.decode(Double.self, forKey: .proteinConsumed)
        entries = try container.decodeIfPresent([ProteinEntry].self, forKey: .entries) ?? []
    }
}
