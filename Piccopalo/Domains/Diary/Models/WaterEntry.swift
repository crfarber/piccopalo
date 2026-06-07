import Foundation

struct WaterEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let dayRecordId: UUID
    let milliliters: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        dayRecordId: UUID,
        milliliters: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dayRecordId = dayRecordId
        self.milliliters = milliliters
        self.createdAt = createdAt
    }
}
