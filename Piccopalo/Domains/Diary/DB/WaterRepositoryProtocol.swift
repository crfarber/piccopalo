import Foundation

protocol WaterRepositoryProtocol: AnyObject {
    func addWaterEntry(
        dayRecordId: UUID,
        milliliters: Int,
        dateISO: String,
        entryId: UUID?,
        createdAt: Date?
    ) async throws -> WaterEntry
    func waterEntriesForDay(_ date: String) async throws -> [WaterEntry]
    func deleteWaterEntry(_ id: UUID) async throws
    func totalWaterForDay(_ date: String) async throws -> Int
}
