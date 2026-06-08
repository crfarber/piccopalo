import Foundation

struct ExerciseSeedItem: Encodable {
    let name: String
    let category: String
    let level: String?
    let instructions: String?
    let thumbnailPath: String?
    let sourceId: String

    enum CodingKeys: String, CodingKey {
        case name, category, level, instructions
        case thumbnailPath = "thumbnail_path"
        case sourceId = "source_id"
    }
}

protocol ExerciseRepositoryProtocol: AnyObject {
    /// Standaard-oefeningen (user_id null) plus de eigen oefeningen.
    func fetchAll() async throws -> [Exercise]
    func fetch(category: ExerciseCategory) async throws -> [Exercise]
    func addCustom(name: String, category: ExerciseCategory) async throws -> Exercise
    func deleteCustom(id: UUID) async throws
    func countStandardExercises() async throws -> Int
    func seedStandardExercises(batch: [ExerciseSeedItem], replaceAll: Bool) async throws -> Int
}
