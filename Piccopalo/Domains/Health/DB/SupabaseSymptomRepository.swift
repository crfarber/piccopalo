import Foundation
import Supabase

final class SupabaseSymptomRepository: SymptomRepositoryProtocol {
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

    // MARK: - save

    func save(_ entry: SymptomEntry) async throws {
        let uid = try await userId
        let row = SupabaseSymptomRow(from: entry, userId: uid)

        _ = try await client
            .from("symptom_entries")
            .insert(row)
            .execute()
    }

    // MARK: - entries(for:)

    func entries(for dateIso: String) async throws -> [SymptomEntry] {
        let uid = try await userId

        let rows: [SupabaseSymptomRow] = try await client
            .from("symptom_entries")
            .select()
            .eq("user_id", value: uid)
            .eq("date_iso", value: dateIso)
            .order("recorded_at", ascending: true)
            .execute()
            .value

        return rows.map { $0.toEntry() }
    }

    // MARK: - delete

    func delete(_ id: UUID) async throws {
        let uid = try await userId

        _ = try await client
            .from("symptom_entries")
            .delete()
            .eq("user_id", value: uid)
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - DTO

private struct SupabaseSymptomRow: Codable {
    let id: String
    let userId: String
    let dateISO: String
    let recordedAt: String
    let energyLevel: Int?
    let focusLevel: Int?
    let hungerLevel: Int?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateISO = "date_iso"
        case recordedAt = "recorded_at"
        case energyLevel = "energy_level"
        case focusLevel = "focus_level"
        case hungerLevel = "hunger_level"
        case note
    }

    init(from entry: SymptomEntry, userId: String) {
        self.id = entry.id.uuidString
        self.userId = userId
        self.dateISO = entry.dateIso
        let fmt = ISO8601DateFormatter()
        self.recordedAt = fmt.string(from: entry.recordedAt)
        self.energyLevel = entry.energyLevel
        self.focusLevel = entry.focusLevel
        self.hungerLevel = entry.hungerLevel
        self.note = entry.note
    }

    func toEntry() -> SymptomEntry {
        let fmt = ISO8601DateFormatter()
        return SymptomEntry(
            id: UUID(uuidString: id) ?? UUID(),
            dateIso: dateISO,
            recordedAt: fmt.date(from: recordedAt) ?? Date(),
            energyLevel: energyLevel,
            focusLevel: focusLevel,
            hungerLevel: hungerLevel,
            note: note
        )
    }
}
