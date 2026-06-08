import Foundation
import Supabase

final class SupabaseWorkoutRepository: WorkoutRepositoryProtocol {
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

    // MARK: - Schema's

    func fetchTemplates() async throws -> [WorkoutTemplate] {
        let uid = try await userId
        let rows: [SupabaseTemplateRow] = try await client
            .from("workout_templates")
            .select()
            .eq("user_id", value: uid)
            .order("day_of_week", ascending: true)
            .execute()
            .value
        return rows.compactMap { $0.toTemplate() }
    }

    func createTemplate(name: String, dayOfWeek: Int?) async throws -> WorkoutTemplate {
        let uid = try await userId
        guard let userUUID = UUID(uuidString: uid) else {
            throw URLError(.userAuthenticationRequired)
        }
        let template = WorkoutTemplate(userId: userUUID, name: name, dayOfWeek: dayOfWeek)
        let row = SupabaseTemplateRow(from: template)

        let inserted: SupabaseTemplateRow = try await client
            .from("workout_templates")
            .insert(row)
            .select()
            .single()
            .execute()
            .value

        return inserted.toTemplate() ?? template
    }

    func updateTemplate(_ template: WorkoutTemplate) async throws {
        let uid = try await userId
        let row = SupabaseTemplateRow(from: template)
        _ = try await client
            .from("workout_templates")
            .update(row)
            .eq("id", value: template.id.uuidString)
            .eq("user_id", value: uid)
            .execute()
    }

    func deleteTemplate(id: UUID) async throws {
        let uid = try await userId
        _ = try await client
            .from("workout_templates")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: uid)
            .execute()
    }

    // MARK: - Template exercises

    func fetchTemplateExercises(templateId: UUID) async throws -> [WorkoutTemplateExercise] {
        let rows: [SupabaseTemplateExerciseRow] = try await client
            .from("workout_template_exercises")
            .select()
            .eq("template_id", value: templateId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value

        let items = rows.map { $0.toItem() }
        let exercises = try await fetchExercises(ids: items.map { $0.exerciseId })

        return items.map { item in
            var copy = item
            copy.exercise = exercises[item.exerciseId]
            return copy
        }
    }

    func addExerciseToTemplate(_ item: WorkoutTemplateExercise) async throws {
        let row = SupabaseTemplateExerciseRow(from: item)
        _ = try await client
            .from("workout_template_exercises")
            .insert(row)
            .execute()
    }

    func updateTemplateExercise(_ item: WorkoutTemplateExercise) async throws {
        let row = SupabaseTemplateExerciseRow(from: item)
        _ = try await client
            .from("workout_template_exercises")
            .update(row)
            .eq("id", value: item.id.uuidString)
            .execute()
    }

    func removeExerciseFromTemplate(id: UUID) async throws {
        _ = try await client
            .from("workout_template_exercises")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func reorderTemplateExercises(_ items: [WorkoutTemplateExercise]) async throws {
        for (index, item) in items.enumerated() where item.sortOrder != index {
            var updated = item
            updated.sortOrder = index
            try await updateTemplateExercise(updated)
        }
    }

    // MARK: - Sessies

    func startSession(dateIso: String, templateId: UUID?) async throws -> WorkoutSession {
        let uid = try await userId
        guard let userUUID = UUID(uuidString: uid) else {
            throw URLError(.userAuthenticationRequired)
        }
        let session = WorkoutSession(
            userId: userUUID,
            dateIso: dateIso,
            templateId: templateId,
            startedAt: Date()
        )
        let row = SupabaseSessionRow(from: session)

        let inserted: SupabaseSessionRow = try await client
            .from("workout_sessions")
            .insert(row)
            .select()
            .single()
            .execute()
            .value

        return inserted.toSession() ?? session
    }

    func finishSession(id: UUID, note: String?) async throws {
        let uid = try await userId
        let payload = SupabaseSessionFinishPayload(
            finishedAt: FitnessDate.string(from: Date()),
            note: note
        )
        _ = try await client
            .from("workout_sessions")
            .update(payload)
            .eq("id", value: id.uuidString)
            .eq("user_id", value: uid)
            .execute()
    }

    func updateSessionNote(id: UUID, note: String?) async throws {
        let uid = try await userId
        let payload = SupabaseSessionNotePayload(note: note)
        _ = try await client
            .from("workout_sessions")
            .update(payload)
            .eq("id", value: id.uuidString)
            .eq("user_id", value: uid)
            .execute()
    }

    func fetchSessions(for dateIso: String) async throws -> [WorkoutSession] {
        let uid = try await userId
        let rows: [SupabaseSessionRow] = try await client
            .from("workout_sessions")
            .select()
            .eq("user_id", value: uid)
            .eq("date_iso", value: dateIso)
            .order("started_at", ascending: false)
            .execute()
            .value
        return rows.compactMap { $0.toSession() }
    }

    func fetchSessions(fromDateIso: String, toDateIso: String) async throws -> [WorkoutSession] {
        let uid = try await userId
        let rows: [SupabaseSessionRow] = try await client
            .from("workout_sessions")
            .select()
            .eq("user_id", value: uid)
            .gte("date_iso", value: fromDateIso)
            .lte("date_iso", value: toDateIso)
            .order("date_iso", ascending: true)
            .order("started_at", ascending: false)
            .execute()
            .value
        return rows.compactMap { $0.toSession() }
    }

    func fetchRecentSessions(limit: Int) async throws -> [WorkoutSession] {
        let uid = try await userId
        let rows: [SupabaseSessionRow] = try await client
            .from("workout_sessions")
            .select()
            .eq("user_id", value: uid)
            .order("date_iso", ascending: false)
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.compactMap { $0.toSession() }
    }

    func deleteSession(id: UUID) async throws {
        let uid = try await userId
        _ = try await client
            .from("workout_sessions")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: uid)
            .execute()
    }

    // MARK: - Sets

    func logSet(_ set: WorkoutSet) async throws {
        let row = SupabaseSetRow(from: set)
        _ = try await client
            .from("workout_sets")
            .insert(row)
            .execute()
    }

    func updateSet(_ set: WorkoutSet) async throws {
        let row = SupabaseSetRow(from: set)
        _ = try await client
            .from("workout_sets")
            .update(row)
            .eq("id", value: set.id.uuidString)
            .execute()
    }

    func deleteSet(id: UUID) async throws {
        _ = try await client
            .from("workout_sets")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchSets(for sessionId: UUID) async throws -> [WorkoutSet] {
        let rows: [SupabaseSetRow] = try await client
            .from("workout_sets")
            .select()
            .eq("session_id", value: sessionId.uuidString)
            .order("exercise_id", ascending: true)
            .order("set_number", ascending: true)
            .execute()
            .value
        return rows.map { $0.toSet() }
    }

    // MARK: - Vorige sessie referentie

    func fetchPreviousSets(exerciseId: UUID, before dateIso: String) async throws -> PreviousSetSummary? {
        let uid = try await userId

        // Recente sessies (gesorteerd nieuw -> oud) vóór de gevraagde datum.
        let sessionRows: [SupabaseSessionRefRow] = try await client
            .from("workout_sessions")
            .select("id, date_iso")
            .eq("user_id", value: uid)
            .lt("date_iso", value: dateIso)
            .order("date_iso", ascending: false)
            .limit(30)
            .execute()
            .value

        guard !sessionRows.isEmpty else { return nil }

        let sessionIds = sessionRows.map { $0.id }
        let dateBySession = Dictionary(uniqueKeysWithValues: sessionRows.map { ($0.id, $0.dateIso) })

        // Alle sets voor deze oefening binnen die sessies in één query.
        let setRows: [SupabaseSetRow] = try await client
            .from("workout_sets")
            .select()
            .in("session_id", values: sessionIds)
            .eq("exercise_id", value: exerciseId.uuidString)
            .order("set_number", ascending: true)
            .execute()
            .value

        guard !setRows.isEmpty else { return nil }

        // Kies de meest recente sessie (eerst in sessionRows) die sets bevat.
        let setsBySession = Dictionary(grouping: setRows.map { $0.toSet() }, by: { $0.sessionId.uuidString })
        guard let chosenId = sessionIds.first(where: { setsBySession[$0] != nil }),
              let sets = setsBySession[chosenId],
              let sessionDate = dateBySession[chosenId] else {
            return nil
        }

        let name = try await exerciseName(id: exerciseId) ?? "Onbekend"

        return PreviousSetSummary(
            exerciseId: exerciseId,
            exerciseName: name,
            dateIso: sessionDate,
            sets: sets.sorted { $0.setNumber < $1.setNumber }
        )
    }

    // MARK: - Helpers

    private func fetchExercises(ids: [UUID]) async throws -> [UUID: Exercise] {
        let unique = Array(Set(ids)).map { $0.uuidString }
        guard !unique.isEmpty else { return [:] }

        let rows: [SupabaseExerciseLookupRow] = try await client
            .from("exercises")
            .select()
            .in("id", values: unique)
            .execute()
            .value

        var map: [UUID: Exercise] = [:]
        for row in rows {
            if let exercise = row.toExercise() {
                map[exercise.id] = exercise
            }
        }
        return map
    }

    private func exerciseName(id: UUID) async throws -> String? {
        let rows: [SupabaseExerciseLookupRow] = try await client
            .from("exercises")
            .select("id, user_id, name, category, is_custom")
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.name
    }
}

// MARK: - Date parsing (timestamptz met of zonder fractionele seconden)

enum FitnessDate {
    private static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ string: String?) -> Date? {
        guard let string else { return nil }
        return withFractional.date(from: string) ?? plain.date(from: string)
    }

    static func string(from date: Date) -> String {
        withFractional.string(from: date)
    }
}

// MARK: - DTO's

private struct SupabaseTemplateRow: Codable {
    let id: String
    let userId: String
    let name: String
    let dayOfWeek: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case dayOfWeek = "day_of_week"
    }

    init(from template: WorkoutTemplate) {
        self.id = template.id.uuidString
        self.userId = template.userId.uuidString
        self.name = template.name
        self.dayOfWeek = template.dayOfWeek
    }

    func toTemplate() -> WorkoutTemplate? {
        guard let templateId = UUID(uuidString: id),
              let userUUID = UUID(uuidString: userId) else { return nil }
        return WorkoutTemplate(id: templateId, userId: userUUID, name: name, dayOfWeek: dayOfWeek)
    }
}

private struct SupabaseTemplateExerciseRow: Codable {
    let id: String
    let templateId: String
    let exerciseId: String
    let sortOrder: Int
    let targetSets: Int?
    let targetReps: Int?
    let targetWeightKg: Double?
    let targetRestSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case exerciseId = "exercise_id"
        case sortOrder = "sort_order"
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetWeightKg = "target_weight_kg"
        case targetRestSeconds = "target_rest_seconds"
    }

    init(from item: WorkoutTemplateExercise) {
        self.id = item.id.uuidString
        self.templateId = item.templateId.uuidString
        self.exerciseId = item.exerciseId.uuidString
        self.sortOrder = item.sortOrder
        self.targetSets = item.targetSets
        self.targetReps = item.targetReps
        self.targetWeightKg = item.targetWeightKg
        self.targetRestSeconds = item.targetRestSeconds
    }

    func toItem() -> WorkoutTemplateExercise {
        WorkoutTemplateExercise(
            id: UUID(uuidString: id) ?? UUID(),
            templateId: UUID(uuidString: templateId) ?? UUID(),
            exerciseId: UUID(uuidString: exerciseId) ?? UUID(),
            sortOrder: sortOrder,
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeightKg: targetWeightKg,
            targetRestSeconds: targetRestSeconds
        )
    }
}

private struct SupabaseSessionRow: Codable {
    let id: String
    let userId: String
    let dateIso: String
    let templateId: String?
    let startedAt: String?
    let finishedAt: String?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateIso = "date_iso"
        case templateId = "template_id"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case note
    }

    init(from session: WorkoutSession) {
        self.id = session.id.uuidString
        self.userId = session.userId.uuidString
        self.dateIso = session.dateIso
        self.templateId = session.templateId?.uuidString
        self.startedAt = session.startedAt.map { FitnessDate.string(from: $0) }
        self.finishedAt = session.finishedAt.map { FitnessDate.string(from: $0) }
        self.note = session.note
    }

    func toSession() -> WorkoutSession? {
        guard let sessionId = UUID(uuidString: id),
              let userUUID = UUID(uuidString: userId) else { return nil }
        return WorkoutSession(
            id: sessionId,
            userId: userUUID,
            dateIso: dateIso,
            templateId: templateId.flatMap { UUID(uuidString: $0) },
            startedAt: FitnessDate.parse(startedAt),
            finishedAt: FitnessDate.parse(finishedAt),
            note: note
        )
    }
}

private struct SupabaseSessionFinishPayload: Codable {
    let finishedAt: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case finishedAt = "finished_at"
        case note
    }
}

private struct SupabaseSessionNotePayload: Codable {
    let note: String?
}

private struct SupabaseSessionRefRow: Codable {
    let id: String
    let dateIso: String

    enum CodingKeys: String, CodingKey {
        case id
        case dateIso = "date_iso"
    }
}

private struct SupabaseSetRow: Codable {
    let id: String
    let sessionId: String
    let exerciseId: String
    let setNumber: Int
    let reps: Int?
    let weightKg: Double?
    let restSeconds: Int?
    let note: String?
    let loggedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weightKg = "weight_kg"
        case restSeconds = "rest_seconds"
        case note
        case loggedAt = "logged_at"
    }

    init(from set: WorkoutSet) {
        self.id = set.id.uuidString
        self.sessionId = set.sessionId.uuidString
        self.exerciseId = set.exerciseId.uuidString
        self.setNumber = set.setNumber
        self.reps = set.reps
        self.weightKg = set.weightKg
        self.restSeconds = set.restSeconds
        self.note = set.note
        self.loggedAt = FitnessDate.string(from: set.loggedAt)
    }

    func toSet() -> WorkoutSet {
        WorkoutSet(
            id: UUID(uuidString: id) ?? UUID(),
            sessionId: UUID(uuidString: sessionId) ?? UUID(),
            exerciseId: UUID(uuidString: exerciseId) ?? UUID(),
            setNumber: setNumber,
            reps: reps,
            weightKg: weightKg,
            restSeconds: restSeconds,
            note: note,
            loggedAt: FitnessDate.parse(loggedAt) ?? Date()
        )
    }
}

private struct SupabaseExerciseLookupRow: Codable {
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
