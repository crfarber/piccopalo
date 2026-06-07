import Foundation

protocol WaterRepositoryProtocol: AnyObject {
    func addWaterEntry(dayRecordId: UUID, milliliters: Int) async throws -> WaterEntry
    func waterEntriesForDay(_ date: String) async throws -> [WaterEntry]
    func deleteWaterEntry(_ id: UUID) async throws
    func totalWaterForDay(_ date: String) async throws -> Int
}
