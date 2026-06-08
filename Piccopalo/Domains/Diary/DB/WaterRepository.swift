import Foundation
import Supabase

final class SupabaseWaterRepository: WaterRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    private let auth = SupabaseManager.shared.client.auth

    private var userId: String {
        get async throws {
            guard let uid = try? await auth.session.user.id.uuidString else {
                throw URLError(.userAuthenticationRequired)
            }
            return uid
        }
    }

    // MARK: - addWaterEntry

    func addWaterEntry(
        dayRecordId: UUID,
        milliliters: Int,
        dateISO: String,
        entryId: UUID? = nil,
        createdAt: Date? = nil
    ) async throws -> WaterEntry {
        let uid = try await userId
        let entry = WaterEntry(
            id: entryId ?? UUID(),
            dayRecordId: dayRecordId,
            milliliters: milliliters,
            createdAt: createdAt ?? Date()
        )
        let row = SupabaseWaterRow(from: entry, userId: uid, dateISO: dateISO)

        _ = try await client
            .from("water_entries")
            .insert(row)
            .execute()

        return entry
    }

    // MARK: - waterEntriesForDay

    func waterEntriesForDay(_ date: String) async throws -> [WaterEntry] {
        let uid = try await userId

        let rows: [SupabaseWaterRow] = try await client
            .from("water_entries")
            .select()
            .eq("user_id", value: uid)
            .eq("date_iso", value: date)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map { $0.toEntry() }
    }

    // MARK: - deleteWaterEntry

    func deleteWaterEntry(_ id: UUID) async throws {
        let uid = try await userId

        _ = try await client
            .from("water_entries")
            .delete()
            .eq("user_id", value: uid)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - totalWaterForDay

    func totalWaterForDay(_ date: String) async throws -> Int {
        let entries = try await waterEntriesForDay(date)
        return entries.reduce(0) { $0 + $1.milliliters }
    }
}

// MARK: - DTO

private struct SupabaseWaterRow: Codable {
    let id: String
    let userId: String
    let dateISO: String
    let milliliters: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateISO = "date_iso"
        case milliliters
        case createdAt = "created_at"
    }

    init(from entry: WaterEntry, userId: String, dateISO: String) {
        self.id = entry.id.uuidString
        self.userId = userId
        self.dateISO = dateISO
        self.milliliters = entry.milliliters
        let fmt = ISO8601DateFormatter()
        self.createdAt = fmt.string(from: entry.createdAt)
    }

    func toEntry() -> WaterEntry {
        let fmt = ISO8601DateFormatter()
        return WaterEntry(
            id: UUID(uuidString: id) ?? UUID(),
            dayRecordId: UUID(),
            milliliters: milliliters,
            createdAt: fmt.date(from: createdAt) ?? Date()
        )
    }

}
