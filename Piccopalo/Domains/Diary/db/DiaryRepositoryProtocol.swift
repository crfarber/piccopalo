import Foundation

protocol DiaryRepositoryProtocol: AnyObject {
    func day(for dateISO: String) -> DayRecord?
    func save(_ record: DayRecord)
    func allDaysSorted() -> [DayRecord]
}
