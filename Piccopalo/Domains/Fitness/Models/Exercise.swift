import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID?       // nil = standaard-oefening (voor iedereen)
    let name: String
    let category: ExerciseCategory
    let isCustom: Bool
    var level: String?
    var instructions: String?
    var thumbnailPath: String?
    var sourceId: String?

    private static let thumbnailBase =
        "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises/"

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        name: String,
        category: ExerciseCategory,
        isCustom: Bool = false,
        level: String? = nil,
        instructions: String? = nil,
        thumbnailPath: String? = nil,
        sourceId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.category = category
        self.isCustom = isCustom
        self.level = level
        self.instructions = instructions
        self.thumbnailPath = thumbnailPath
        self.sourceId = sourceId
    }

    var thumbnailURL: URL? {
        guard let path = thumbnailPath else { return nil }
        return URL(string: Self.thumbnailBase + path)
    }

    var difficultyLabel: String {
        switch level?.lowercased() {
        case "beginner": return "Beginner"
        case "intermediate": return "Gemiddeld"
        case "expert": return "Gevorderd"
        default: return ""
        }
    }
}
