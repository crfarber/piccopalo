import Foundation

protocol WorkoutRepositoryProtocol: AnyObject {
    // Schema's
    func fetchTemplates() async throws -> [WorkoutTemplate]
    func createTemplate(name: String, dayOfWeek: Int?) async throws -> WorkoutTemplate
    func updateTemplate(_ template: WorkoutTemplate) async throws
    func deleteTemplate(id: UUID) async throws

    // Oefeningen binnen een schema (exercise ingevuld na join)
    func fetchTemplateExercises(templateId: UUID) async throws -> [WorkoutTemplateExercise]
    func addExerciseToTemplate(_ item: WorkoutTemplateExercise) async throws
    func updateTemplateExercise(_ item: WorkoutTemplateExercise) async throws
    func removeExerciseFromTemplate(id: UUID) async throws
    func reorderTemplateExercises(_ items: [WorkoutTemplateExercise]) async throws

    // Sessies
    func startSession(dateIso: String, templateId: UUID?) async throws -> WorkoutSession
    func finishSession(id: UUID, note: String?) async throws
    func updateSessionNote(id: UUID, note: String?) async throws
    func fetchSessions(for dateIso: String) async throws -> [WorkoutSession]
    func fetchSessions(fromDateIso: String, toDateIso: String) async throws -> [WorkoutSession]
    func fetchRecentSessions(limit: Int) async throws -> [WorkoutSession]
    func deleteSession(id: UUID) async throws

    // Sets
    func logSet(_ set: WorkoutSet) async throws
    func updateSet(_ set: WorkoutSet) async throws
    func deleteSet(id: UUID) async throws
    func fetchSets(for sessionId: UUID) async throws -> [WorkoutSet]

    // Referentie naar vorige keer
    func fetchPreviousSets(exerciseId: UUID, before dateIso: String) async throws -> PreviousSetSummary?
}
