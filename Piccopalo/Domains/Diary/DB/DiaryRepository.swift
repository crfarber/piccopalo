import Foundation
import Supabase

final class SupabaseDiaryRepository: DiaryRepositoryProtocol {
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

    // MARK: - day(for:)

    func day(for dateISO: String) async -> DayRecord? {
        guard let uid = try? await auth.session.user.id.uuidString else { return nil }

        // Dag ophalen
        let days: [SupabaseDayRow] = (try? await client
            .from("diary_days")
            .select()
            .eq("user_id", value: uid)
            .eq("date_iso", value: dateISO)
            .limit(1)
            .execute()
            .value) ?? []

        guard let day = days.first else { return nil }

        // Entries ophalen
        let entries: [SupabaseEntryRow] = (try? await client
            .from("diary_entries")
            .select()
            .eq("user_id", value: uid)
            .eq("date_iso", value: dateISO)
            .execute()
            .value) ?? []

        return day.toDayRecord(entries: entries.map { $0.toEntry() })
    }

    // MARK: - save(_:)

    func save(_ record: DayRecord) async {
        guard let uid = try? await auth.session.user.id.uuidString else { return }

        let dayRow = SupabaseDayRow(from: record, userId: uid)
        _ = try? await client
            .from("diary_days")
            .upsert(dayRow, onConflict: "user_id,date_iso")
            .execute()

        // Verwijder bestaande entries voor die dag en insert opnieuw
        _ = try? await client
            .from("diary_entries")
            .delete()
            .eq("user_id", value: uid)
            .eq("date_iso", value: record.date)
            .execute()

        if !record.entries.isEmpty {
            let entryRows = record.entries.map { SupabaseEntryRow(from: $0, dateISO: record.date, userId: uid) }
            _ = try? await client
                .from("diary_entries")
                .insert(entryRows)
                .execute()
        }
    }

    // MARK: - allDaysSorted()

    func allDaysSorted() async -> [DayRecord] {
        guard let uid = try? await auth.session.user.id.uuidString else { return [] }

        let days: [SupabaseDayRow] = (try? await client
            .from("diary_days")
            .select()
            .eq("user_id", value: uid)
            .order("date_iso", ascending: false)
            .execute()
            .value) ?? []

        let entries: [SupabaseEntryRow] = (try? await client
            .from("diary_entries")
            .select()
            .eq("user_id", value: uid)
            .execute()
            .value) ?? []

        let entryMap = Dictionary(grouping: entries, by: \.dateISO)

        return days.map { day in
            let dayEntries = entryMap[day.dateISO]?.map { $0.toEntry() } ?? []
            return day.toDayRecord(entries: dayEntries)
        }
    }
}

// MARK: - DTO's

private struct SupabaseDayRow: Codable {
    let userId: String
    let dateISO: String
    let weight: Double
    let activityFactor: Double
    let proteinGoal: Double
    let proteinConsumed: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case dateISO = "date_iso"
        case weight
        case activityFactor = "activity_factor"
        case proteinGoal = "protein_goal"
        case proteinConsumed = "protein_consumed"
    }

    init(from record: DayRecord, userId: String) {
        self.userId = userId
        self.dateISO = record.date
        self.weight = record.weight
        self.activityFactor = record.activityFactor
        self.proteinGoal = record.proteinGoal
        self.proteinConsumed = record.proteinConsumed
    }

    func toDayRecord(entries: [ProteinEntry]) -> DayRecord {
        DayRecord(
            date: dateISO,
            weight: weight,
            activityFactor: activityFactor,
            proteinGoal: proteinGoal,
            proteinConsumed: proteinConsumed,
            entries: entries,
            stepsCount: nil  // Steps are fetched on-demand via HealthKit
        )
    }
}

private struct SupabaseEntryRow: Codable {
    let id: String
    let userId: String
    let dateISO: String
    let sourceName: String
    let quantity: Double
    let unit: String
    let proteinPer100: Double
    let proteinAmount: Double
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateISO = "date_iso"
        case sourceName = "source_name"
        case quantity
        case unit
        case proteinPer100 = "protein_per100"
        case proteinAmount = "protein_amount"
        case createdAt = "created_at"
    }

    init(from entry: ProteinEntry, dateISO: String, userId: String) {
        self.id = entry.id.uuidString
        self.userId = userId
        self.dateISO = dateISO
        self.sourceName = entry.sourceName
        self.quantity = entry.quantity
        self.unit = entry.unit.rawValue
        self.proteinPer100 = entry.proteinPer100
        self.proteinAmount = entry.proteinAmount
        let fmt = ISO8601DateFormatter()
        self.createdAt = fmt.string(from: entry.createdAt)
    }

    func toEntry() -> ProteinEntry {
        let fmt = ISO8601DateFormatter()
        return ProteinEntry(
            id: UUID(uuidString: id) ?? UUID(),
            sourceName: sourceName,
            quantity: quantity,
            unit: ProteinEntryUnit(rawValue: unit) ?? .grams,
            proteinPer100: proteinPer100,
            proteinAmount: proteinAmount,
            createdAt: fmt.date(from: createdAt) ?? Date()
        )
    }
}
