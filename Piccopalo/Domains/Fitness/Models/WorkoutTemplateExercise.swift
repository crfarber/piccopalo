import Foundation

/// Oefening binnen een schema, met optionele doelwaarden.
/// `exercise` wordt na een fetch ingevuld vanuit de oefeningen-bibliotheek (niet in de DB-tabel).
struct WorkoutTemplateExercise: Identifiable, Codable, Hashable {
    let id: UUID
    let templateId: UUID
    let exerciseId: UUID
    var sortOrder: Int
    var targetSets: Int?
    var targetReps: Int?
    var targetWeightKg: Double?
    var targetRestSeconds: Int?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        templateId: UUID,
        exerciseId: UUID,
        sortOrder: Int = 0,
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        targetWeightKg: Double? = nil,
        targetRestSeconds: Int? = 90,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.exerciseId = exerciseId
        self.sortOrder = sortOrder
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.targetRestSeconds = targetRestSeconds
        self.exercise = exercise
    }
}
