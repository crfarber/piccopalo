import Foundation
import Supabase

final class SupabaseBloodSugarRepository: BloodSugarRepositoryProtocol {
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

    func save(_ entry: BloodSugarEntry) async throws {
        let uid = try await userId
        let row = SupabaseBloodSugarRow(from: entry, userId: uid)

        _ = try await client
            .from("blood_sugar_entries")
            .insert(row)
            .execute()
    }

    // MARK: - readings(for:)

    func readings(for dateIso: String) async throws -> [BloodSugarEntry] {
        let uid = try await userId

        let rows: [SupabaseBloodSugarRow] = try await client
            .from("blood_sugar_entries")
            .select()
            .eq("user_id", value: uid)
            .eq("date_iso", value: dateIso)
            .order("recorded_at", ascending: true)
            .execute()
            .value

        return rows.map { $0.toEntry() }
    }

    // MARK: - readings(from:to:)

    func readings(from startDate: String, to endDate: String) async throws -> [BloodSugarEntry] {
        let uid = try await userId

        let rows: [SupabaseBloodSugarRow] = try await client
            .from("blood_sugar_entries")
            .select()
            .eq("user_id", value: uid)
            .gte("date_iso", value: startDate)
            .lte("date_iso", value: endDate)
            .order("recorded_at", ascending: true)
            .execute()
            .value

        return rows.map { $0.toEntry() }
    }

    // MARK: - delete

    func delete(_ id: UUID) async throws {
        let uid = try await userId

        _ = try await client
            .from("blood_sugar_entries")
            .delete()
            .eq("user_id", value: uid)
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - DTO

private struct SupabaseBloodSugarRow: Codable {
    let id: String
    let userId: String
    let dateISO: String
    let recordedAt: String
    let valueMmol: Double
    let moment: String?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateISO = "date_iso"
        case recordedAt = "recorded_at"
        case valueMmol = "value_mmol"
        case moment
        case note
    }

    init(from entry: BloodSugarEntry, userId: String) {
        self.id = entry.id.uuidString
        self.userId = userId
        self.dateISO = entry.dateIso
        let fmt = ISO8601DateFormatter()
        self.recordedAt = fmt.string(from: entry.recordedAt)
        self.valueMmol = entry.valueMmol
        self.moment = entry.moment?.rawValue
        self.note = entry.note
    }

    func toEntry() -> BloodSugarEntry {
        let fmt = ISO8601DateFormatter()
        return BloodSugarEntry(
            id: UUID(uuidString: id) ?? UUID(),
            dateIso: dateISO,
            recordedAt: fmt.date(from: recordedAt) ?? Date(),
            valueMmol: valueMmol,
            moment: moment.flatMap { BSMoment(rawValue: $0) },
            note: note
        )
    }
}
