import Foundation

protocol SymptomRepositoryProtocol: AnyObject {
    func save(_ entry: SymptomEntry) async throws
    func entries(for dateIso: String) async throws -> [SymptomEntry]
    func delete(_ id: UUID) async throws
}
