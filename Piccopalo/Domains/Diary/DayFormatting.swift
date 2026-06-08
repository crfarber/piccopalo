import Foundation

enum DayFormatting {
    private static let iso: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let weekdayShortNL: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static func date(fromISODate string: String) -> Date? {
        iso.date(from: string)
    }

    static func isoString(from date: Date) -> String {
        iso.string(from: date)
    }

    /// Korte label voor weekstrip (2 tekens, bv. "MA").
    static func weekStripLabel(for date: Date) -> String {
        let short = weekdayShortNL.string(from: date)
        guard short.count >= 2 else { return short.uppercased() }
        return String(short.prefix(2)).uppercased()
    }
}
