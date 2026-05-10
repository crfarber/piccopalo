import Foundation

protocol DiaryRepositoryProtocol: AnyObject {
    func day(for dateISO: String) async -> DayRecord?
    func save(_ record: DayRecord) async
    func allDaysSorted() async -> [DayRecord]
}