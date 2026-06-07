import Foundation
import Supabase

final class SupabaseUserProfileRepository: UserProfileRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    private let auth = SupabaseManager.shared.client.auth

    func loadAccount() async -> AccountData? {
        guard let uid = try? await auth.session.user.id.uuidString else { return nil }
        let rows: [SupabaseProfileRow] = (try? await client
            .from("user_profiles")
            .select()
            .eq("id", value: uid)
            .limit(1)
            .execute()
            .value) ?? []
        return rows.first?.toAccountData()
    }

    func saveAccount(_ data: AccountData) async {
        guard let uid = try? await auth.session.user.id.uuidString else { return }
        let row = SupabaseProfileRow(from: data, userId: uid)
        _ = try? await client
            .from("user_profiles")
            .upsert(row, onConflict: "id")
            .execute()
    }
}

private struct SupabaseProfileRow: Codable {
    let id: String
    let name: String
    let weight: Double
    let height: Double
    let activityFactor: Double
    let waterGoalMl: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case weight
        case height
        case activityFactor = "activity_factor"
        case waterGoalMl = "water_goal_ml"
    }

    init(from data: AccountData, userId: String) {
        self.id = userId
        self.name = data.name
        self.weight = data.weight
        self.height = data.height
        self.activityFactor = data.activityFactor
        self.waterGoalMl = data.waterGoalMl
    }

    func toAccountData() -> AccountData {
        AccountData(name: name, weight: weight, height: height, activityFactor: activityFactor, waterGoalMl: waterGoalMl)
    }
}