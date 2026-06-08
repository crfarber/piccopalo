import Foundation
import Supabase

final class SupabaseExerciseRepository: ExerciseRepositoryProtocol {
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

    // MARK: - fetchAll

    func fetchAll() async throws -> [Exercise] {
        let rows: [SupabaseExerciseRow] = try await client
            .from("exercises")
            .select()
            .order("category", ascending: true)
            .order("name", ascending: true)
            .execute()
            .value

        return rows.compactMap { $0.toExercise() }
    }

    // MARK: - fetch(category:)

    func fetch(category: ExerciseCategory) async throws -> [Exercise] {
        let rows: [SupabaseExerciseRow] = try await client
            .from("exercises")
            .select()
            .eq("category", value: category.rawValue)
            .order("name", ascending: true)
            .execute()
            .value

        return rows.compactMap { $0.toExercise() }
    }

    // MARK: - addCustom

    func addCustom(name: String, category: ExerciseCategory) async throws -> Exercise {
        let uid = try await userId
        let exercise = Exercise(
            userId: UUID(uuidString: uid),
            name: name,
            category: category,
            isCustom: true
        )
        let row = SupabaseExerciseRow(from: exercise, userId: uid)

        let inserted: SupabaseExerciseRow = try await client
            .from("exercises")
            .insert(row)
            .select()
            .single()
            .execute()
            .value

        return inserted.toExercise() ?? exercise
    }

    // MARK: - deleteCustom

    func deleteCustom(id: UUID) async throws {
        let uid = try await userId

        _ = try await client
            .from("exercises")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: uid)
            .eq("is_custom", value: true)
            .execute()
    }

    // MARK: - import

    func countStandardExercises() async throws -> Int {
        let rows: [SupabaseExerciseCountRow] = try await client
            .from("exercises")
            .select("id, user_id, is_custom")
            .eq("is_custom", value: false)
            .limit(1000)
            .execute()
            .value
        return rows.filter { $0.userId == nil }.count
    }

    func seedStandardExercises(batch: [ExerciseSeedItem], replaceAll: Bool) async throws -> Int {
        _ = try await userId
        let params = SeedStandardExercisesParams(batch: batch, replaceAll: replaceAll)
        let count: Int = try await client
            .rpc("seed_standard_exercises", params: params)
            .execute()
            .value
        return count
    }
}

// MARK: - RPC params

private struct SeedStandardExercisesParams: Encodable {
    let batch: [ExerciseSeedItem]
    let replaceAll: Bool

    enum CodingKeys: String, CodingKey {
        case batch
        case replaceAll = "replace_all"
    }
}

// MARK: - DTO

private struct SupabaseExerciseCountRow: Codable {
    let id: String
    let userId: String?
    let isCustom: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case isCustom = "is_custom"
    }
}

private struct SupabaseExerciseRow: Codable {
    let id: String
    let userId: String?
    let name: String
    let category: String
    let isCustom: Bool
    let level: String?
    let instructions: String?
    let thumbnailPath: String?
    let sourceId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case category
        case isCustom = "is_custom"
        case level
        case instructions
        case thumbnailPath = "thumbnail_path"
        case sourceId = "source_id"
    }

    init(from exercise: Exercise, userId: String) {
        self.id = exercise.id.uuidString
        self.userId = userId
        self.name = exercise.name
        self.category = exercise.category.rawValue
        self.isCustom = exercise.isCustom
        self.level = exercise.level
        self.instructions = exercise.instructions
        self.thumbnailPath = exercise.thumbnailPath
        self.sourceId = exercise.sourceId
    }

    func toExercise() -> Exercise? {
        guard let category = ExerciseCategory(rawValue: category) else { return nil }
        return Exercise(
            id: UUID(uuidString: id) ?? UUID(),
            userId: userId.flatMap { UUID(uuidString: $0) },
            name: name,
            category: category,
            isCustom: isCustom,
            level: level,
            instructions: instructions,
            thumbnailPath: thumbnailPath,
            sourceId: sourceId
        )
    }
}
