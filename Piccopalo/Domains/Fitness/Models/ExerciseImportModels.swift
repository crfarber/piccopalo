import Foundation

// MARK: - Raw JSON model (free-exercise-db)

struct RawExercise: Codable {
    let id: String
    let name: String
    let category: String
    let equipment: String?
    let level: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let images: [String]

    private static let imageBase =
        "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises/"

    var thumbnailURL: URL? {
        guard let first = images.first else { return nil }
        return URL(string: Self.imageBase + first)
    }

    var piccopaloCategory: ExerciseCategory? {
        guard let muscle = primaryMuscles.first?.lowercased() else { return nil }
        switch muscle {
        case "chest":
            return .borst
        case "lats", "middle back", "lower back", "traps":
            return .rug
        case "shoulders", "neck":
            return .schouders
        case "biceps", "triceps", "forearms":
            return .armen
        case "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors":
            return .benen
        case "abdominals":
            return .core
        default:
            return nil
        }
    }

    var difficultyLabel: String {
        switch level?.lowercased() {
        case "beginner": return "Beginner"
        case "intermediate": return "Gemiddeld"
        case "expert": return "Gevorderd"
        default: return ""
        }
    }

    func toPiccopaloExercise() -> Exercise? {
        guard let category = piccopaloCategory else { return nil }
        return Exercise(
            name: name,
            category: category,
            isCustom: false,
            level: level,
            instructions: instructions.isEmpty ? nil : instructions.joined(separator: "\n\n"),
            thumbnailPath: images.first,
            sourceId: id
        )
    }

    /// Payload voor Supabase RPC `seed_standard_exercises` (snake_case keys).
    func toSeedItem() -> ExerciseSeedItem? {
        guard let category = piccopaloCategory else { return nil }
        return ExerciseSeedItem(
            name: name,
            category: category.rawValue,
            level: level,
            instructions: instructions.isEmpty ? nil : instructions.joined(separator: "\n\n"),
            thumbnailPath: images.first,
            sourceId: id
        )
    }
}
