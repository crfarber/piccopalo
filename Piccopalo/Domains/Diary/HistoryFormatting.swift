import Foundation

enum HistoryFormatting {
    private static let iso: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let dayMonthNL: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let weekdayShortNL: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let weekdayFullNL: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static func date(fromISODate string: String) -> Date? {
        iso.date(from: string)
    }

    static func isoString(from date: Date) -> String {
        iso.string(from: date)
    }

    /// Eerste deel van de titelregel: "Vandaag", "Gisteren", of weekdag.
    static func primaryDayLabel(isoDate: String) -> String {
        guard let parsed = date(fromISODate: isoDate) else { return isoDate }
        let cal = Calendar.current
        if cal.isDateInToday(parsed) { return "Vandaag" }
        if cal.isDateInYesterday(parsed) { return "Gisteren" }
        return weekdayFullNL.string(from: parsed).capitalized
    }

    /// Kalenderdeel op dezelfde regel, bv. "2 mei".
    static func dayAndMonthNL(isoDate: String) -> String {
        guard let parsed = date(fromISODate: isoDate) else { return "" }
        return dayMonthNL.string(from: parsed)
    }

    /// Korte label voor weekstrip (2 tekens, bv. "MA").
    static func weekStripLabel(for date: Date) -> String {
        let short = weekdayShortNL.string(from: date)
        guard short.count >= 2 else { return short.uppercased() }
        return String(short.prefix(2)).uppercased()
    }
}
