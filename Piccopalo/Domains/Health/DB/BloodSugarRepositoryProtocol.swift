import Foundation

protocol BloodSugarRepositoryProtocol: AnyObject {
    func save(_ entry: BloodSugarEntry) async throws
    func readings(for dateIso: String) async throws -> [BloodSugarEntry]
    func readings(from startDate: String, to endDate: String) async throws -> [BloodSugarEntry]
    func delete(_ id: UUID) async throws
}
