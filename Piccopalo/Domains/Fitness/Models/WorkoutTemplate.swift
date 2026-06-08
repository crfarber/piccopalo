import Foundation

/// Trainingsschema. `dayOfWeek` is ISO-weekdag: 1=maandag ... 7=zondag, nil=geen vaste dag.
struct WorkoutTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    var name: String
    var dayOfWeek: Int?

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        dayOfWeek: Int? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.dayOfWeek = dayOfWeek
    }

    var dayLabel: String {
        WorkoutWeekday.label(for: dayOfWeek)
    }

    var planLabel: String {
        dayOfWeek == nil ? "Niet ingepland" : dayLabel
    }
}

/// Hulpmiddel voor ISO-weekdagen (1=maandag ... 7=zondag), los van `Calendar.weekday`
/// (dat 1=zondag is in `en_US`).
enum WorkoutWeekday {
    static let isoDays = Array(1...7)

    static func label(for isoDay: Int?) -> String {
        guard let day = isoDay, let name = fullNames[day] else { return "Geen vaste dag" }
        return name
    }

    static func shortLabel(for isoDay: Int) -> String {
        shortNames[isoDay] ?? "?"
    }

    /// Zet een `Date` om naar ISO-weekdag (1=maandag ... 7=zondag).
    static func isoWeekday(from date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date) // 1=zondag ... 7=zaterdag
        return weekday == 1 ? 7 : weekday - 1
    }

    private static let fullNames: [Int: String] = [
        1: "Maandag", 2: "Dinsdag", 3: "Woensdag", 4: "Donderdag",
        5: "Vrijdag", 6: "Zaterdag", 7: "Zondag"
    ]

    private static let shortNames: [Int: String] = [
        1: "MA", 2: "DI", 3: "WO", 4: "DO", 5: "VR", 6: "ZA", 7: "ZO"
    ]

    /// Maandag t/m zondag van de kalenderweek waarin `date` valt.
    static func datesInCurrentWeek(containing date: Date = Date()) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }
}

enum TrainingWeekDayDotState {
    case empty
    case planned
    case missed
    case completed
}
