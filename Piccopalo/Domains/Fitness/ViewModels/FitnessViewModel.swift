import Foundation
import Combine

@MainActor
class FitnessViewModel: ObservableObject {
    // Bibliotheek + schema's
    @Published var exercises: [Exercise] = []
    @Published var templates: [WorkoutTemplate] = []
    @Published var weekSessionsByDate: [String: WorkoutSession] = [:]

    // Actieve sessie
    @Published var activeSession: WorkoutSession?
    @Published var sessionExercises: [Exercise] = []
    @Published var sessionSets: [WorkoutSet] = []
    @Published var previousSummaries: [UUID: PreviousSetSummary] = [:]

    @Published var errorMessage: String?

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol

    /// Doelwaarden uit het schema, per oefening (voor prefill tijdens loggen).
    private var sessionTargets: [UUID: WorkoutTemplateExercise] = [:]

    init(
        exerciseRepository: ExerciseRepositoryProtocol,
        workoutRepository: WorkoutRepositoryProtocol
    ) {
        self.exerciseRepository = exerciseRepository
        self.workoutRepository = workoutRepository
    }

    // MARK: - Afgeleide data

    var exercisesByCategory: [ExerciseCategory: [Exercise]] {
        Dictionary(grouping: exercises, by: { $0.category })
    }

    func template(forIsoDay isoDay: Int) -> WorkoutTemplate? {
        templates.first { $0.dayOfWeek == isoDay }
    }

    var weekDates: [Date] {
        WorkoutWeekday.datesInCurrentWeek()
    }

    var todayIsoDay: Int {
        WorkoutWeekday.isoWeekday(from: Date())
    }

    var todayDateIso: String {
        DayFormatting.isoString(from: Date())
    }

    var todayTemplate: WorkoutTemplate? {
        template(forIsoDay: todayIsoDay)
    }

    var todaySession: WorkoutSession? {
        weekSessionsByDate[todayDateIso]
    }

    var plannedCount: Int {
        WorkoutWeekday.isoDays.filter { template(forIsoDay: $0) != nil }.count
    }

    var completedCount: Int {
        weekDates.filter { date in
            guard let session = weekSessionsByDate[DayFormatting.isoString(from: date)] else { return false }
            return session.isFinished
        }.count
    }

    var motivationText: String {
        let planned = plannedCount
        let completed = completedCount
        if planned == 0 {
            return completed > 0
                ? "\(completed) training\(completed == 1 ? "" : "en") deze week"
                : "Plan je week door schema's aan dagen te koppelen"
        }
        if completed >= planned {
            return "Week volbracht — top bezig!"
        }
        if completed > 0 {
            return "Lekker bezig — \(completed) van \(planned) trainingen gedaan"
        }
        return "\(planned) training\(planned == 1 ? "" : "en") ingepland deze week"
    }

    func dotState(for date: Date) -> TrainingWeekDayDotState {
        let dateIso = DayFormatting.isoString(from: date)
        let isoDay = WorkoutWeekday.isoWeekday(from: date)
        if let session = weekSessionsByDate[dateIso], session.isFinished {
            return .completed
        }
        if template(forIsoDay: isoDay) != nil {
            let today = Calendar.current.startOfDay(for: Date())
            let day = Calendar.current.startOfDay(for: date)
            return day < today ? .missed : .planned
        }
        return .empty
    }

    func weekDotStates() -> [TrainingWeekDayDotState] {
        weekDates.map { dotState(for: $0) }
    }

    func session(for date: Date) -> WorkoutSession? {
        weekSessionsByDate[DayFormatting.isoString(from: date)]
    }

    func templateName(for session: WorkoutSession) -> String {
        guard let templateId = session.templateId,
              let template = templates.first(where: { $0.id == templateId }) else {
            return "Vrij trainen"
        }
        return template.name
    }

    func exercise(for id: UUID) -> Exercise? {
        exercises.first { $0.id == id } ?? sessionExercises.first { $0.id == id }
    }

    func sets(for exerciseId: UUID) -> [WorkoutSet] {
        sessionSets
            .filter { $0.exerciseId == exerciseId }
            .sorted { $0.setNumber < $1.setNumber }
    }

    func target(for exerciseId: UUID) -> WorkoutTemplateExercise? {
        sessionTargets[exerciseId]
    }

    // MARK: - Laden

    func refresh() async {
        await loadExercises()
        await loadTemplates()
        await loadWeekSessions()
    }

    func loadExercises() async {
        do {
            exercises = try await exerciseRepository.fetchAll()
        } catch {
            errorMessage = "Oefeningen laden mislukt: \(error.localizedDescription)"
        }
    }

    func loadTemplates() async {
        do {
            templates = try await workoutRepository.fetchTemplates()
        } catch {
            errorMessage = "Schema's laden mislukt: \(error.localizedDescription)"
        }
    }

    func loadWeekSessions() async {
        let dates = WorkoutWeekday.datesInCurrentWeek()
        guard let first = dates.first, let last = dates.last else { return }
        let from = DayFormatting.isoString(from: first)
        let to = DayFormatting.isoString(from: last)
        do {
            let sessions = try await workoutRepository.fetchSessions(fromDateIso: from, toDateIso: to)
            var map: [String: WorkoutSession] = [:]
            for session in sessions where session.isFinished {
                if let existing = map[session.dateIso] {
                    let existingEnd = existing.finishedAt ?? .distantPast
                    let candidateEnd = session.finishedAt ?? .distantPast
                    if candidateEnd > existingEnd {
                        map[session.dateIso] = session
                    }
                } else {
                    map[session.dateIso] = session
                }
            }
            weekSessionsByDate = map
        } catch {
            errorMessage = "Trainingen laden mislukt: \(error.localizedDescription)"
        }
    }

    func deleteSession(_ session: WorkoutSession) async {
        do {
            try await workoutRepository.deleteSession(id: session.id)
            weekSessionsByDate.removeValue(forKey: session.dateIso)
            if activeSession?.id == session.id {
                clearActiveSession()
            }
        } catch {
            errorMessage = "Training verwijderen mislukt: \(error.localizedDescription)"
        }
    }

    // MARK: - Oefeningen-bibliotheek

    @discardableResult
    func addCustomExercise(name: String, category: ExerciseCategory) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        do {
            let created = try await exerciseRepository.addCustom(name: trimmed, category: category)
            exercises.append(created)
            exercises.sort { lhs, rhs in
                lhs.category.rawValue == rhs.category.rawValue
                    ? lhs.name < rhs.name
                    : lhs.category.rawValue < rhs.category.rawValue
            }
            return true
        } catch {
            errorMessage = "Oefening toevoegen mislukt: \(error.localizedDescription)"
            return false
        }
    }

    func deleteCustomExercise(_ exercise: Exercise) async {
        guard exercise.isCustom else { return }
        do {
            try await exerciseRepository.deleteCustom(id: exercise.id)
            exercises.removeAll { $0.id == exercise.id }
        } catch {
            errorMessage = "Oefening verwijderen mislukt: \(error.localizedDescription)"
        }
    }

    // MARK: - Schema's

    @discardableResult
    func createTemplate(name: String, dayOfWeek: Int?) async -> WorkoutTemplate? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        do {
            let created = try await workoutRepository.createTemplate(name: trimmed, dayOfWeek: dayOfWeek)
            templates.append(created)
            return created
        } catch {
            errorMessage = "Schema aanmaken mislukt: \(error.localizedDescription)"
            return nil
        }
    }

    func updateTemplate(_ template: WorkoutTemplate) async {
        do {
            try await workoutRepository.updateTemplate(template)
            if let index = templates.firstIndex(where: { $0.id == template.id }) {
                templates[index] = template
            }
        } catch {
            errorMessage = "Schema bijwerken mislukt: \(error.localizedDescription)"
        }
    }

    func assignTemplate(_ template: WorkoutTemplate, toIsoDay isoDay: Int) async {
        for var existing in templates where existing.dayOfWeek == isoDay && existing.id != template.id {
            existing.dayOfWeek = nil
            await updateTemplate(existing)
        }
        var updated = template
        updated.dayOfWeek = isoDay
        await updateTemplate(updated)
    }

    func deleteTemplate(_ template: WorkoutTemplate) async {
        do {
            try await workoutRepository.deleteTemplate(id: template.id)
            templates.removeAll { $0.id == template.id }
        } catch {
            errorMessage = "Schema verwijderen mislukt: \(error.localizedDescription)"
        }
    }

    func templateExercises(for templateId: UUID) async -> [WorkoutTemplateExercise] {
        do {
            return try await workoutRepository.fetchTemplateExercises(templateId: templateId)
        } catch {
            errorMessage = "Schema-oefeningen laden mislukt: \(error.localizedDescription)"
            return []
        }
    }

    func addExercise(_ exercise: Exercise, to templateId: UUID, sortOrder: Int) async {
        let item = WorkoutTemplateExercise(
            templateId: templateId,
            exerciseId: exercise.id,
            sortOrder: sortOrder,
            exercise: exercise
        )
        do {
            try await workoutRepository.addExerciseToTemplate(item)
        } catch {
            errorMessage = "Oefening toevoegen aan schema mislukt: \(error.localizedDescription)"
        }
    }

    func updateTemplateExercise(_ item: WorkoutTemplateExercise) async {
        do {
            try await workoutRepository.updateTemplateExercise(item)
        } catch {
            errorMessage = "Schema-oefening bijwerken mislukt: \(error.localizedDescription)"
        }
    }

    func removeTemplateExercise(_ item: WorkoutTemplateExercise) async {
        do {
            try await workoutRepository.removeExerciseFromTemplate(id: item.id)
        } catch {
            errorMessage = "Oefening verwijderen uit schema mislukt: \(error.localizedDescription)"
        }
    }

    func reorderTemplateExercises(_ items: [WorkoutTemplateExercise]) async {
        do {
            try await workoutRepository.reorderTemplateExercises(items)
        } catch {
            errorMessage = "Volgorde opslaan mislukt: \(error.localizedDescription)"
        }
    }

    // MARK: - Actieve sessie

    func startSession(dateIso: String, template: WorkoutTemplate?) async {
        sessionTargets = [:]
        sessionSets = []
        previousSummaries = [:]
        sessionExercises = []

        do {
            let session = try await workoutRepository.startSession(
                dateIso: dateIso,
                templateId: template?.id
            )
            activeSession = session

            if let template {
                let items = await templateExercises(for: template.id)
                sessionExercises = items.compactMap { $0.exercise }
                for item in items {
                    sessionTargets[item.exerciseId] = item
                }
            }

            await loadPreviousSummaries(before: dateIso)
        } catch {
            errorMessage = "Training starten mislukt: \(error.localizedDescription)"
        }
    }

    func addExerciseToSession(_ exercise: Exercise) async {
        guard !sessionExercises.contains(where: { $0.id == exercise.id }) else { return }
        sessionExercises.append(exercise)
        if let dateIso = activeSession?.dateIso {
            await loadPreviousSummary(exerciseId: exercise.id, before: dateIso)
        }
    }

    func logSet(exerciseId: UUID, reps: Int?, weightKg: Double?, restSeconds: Int?) async {
        guard let session = activeSession else { return }
        let nextNumber = (sets(for: exerciseId).map { $0.setNumber }.max() ?? 0) + 1
        let set = WorkoutSet(
            sessionId: session.id,
            exerciseId: exerciseId,
            setNumber: nextNumber,
            reps: reps,
            weightKg: weightKg,
            restSeconds: restSeconds
        )
        do {
            try await workoutRepository.logSet(set)
            sessionSets.append(set)
        } catch {
            errorMessage = "Set opslaan mislukt: \(error.localizedDescription)"
        }
    }

    func updateSet(_ set: WorkoutSet) async {
        do {
            try await workoutRepository.updateSet(set)
            if let index = sessionSets.firstIndex(where: { $0.id == set.id }) {
                sessionSets[index] = set
            }
        } catch {
            errorMessage = "Set bijwerken mislukt: \(error.localizedDescription)"
        }
    }

    func deleteSet(_ set: WorkoutSet) async {
        do {
            try await workoutRepository.deleteSet(id: set.id)
            sessionSets.removeAll { $0.id == set.id }
        } catch {
            errorMessage = "Set verwijderen mislukt: \(error.localizedDescription)"
        }
    }

    func finishSession(note: String?) async {
        guard let session = activeSession else { return }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = (trimmed?.isEmpty == false) ? trimmed : nil
        do {
            try await workoutRepository.finishSession(id: session.id, note: finalNote)
            activeSession?.finishedAt = Date()
            activeSession?.note = finalNote
            await loadWeekSessions()
        } catch {
            errorMessage = "Training afronden mislukt: \(error.localizedDescription)"
        }
    }

    func saveSessionNote(_ note: String?) async {
        guard let session = activeSession else { return }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = (trimmed?.isEmpty == false) ? trimmed : nil
        do {
            try await workoutRepository.updateSessionNote(id: session.id, note: finalNote)
            activeSession?.note = finalNote
        } catch {
            errorMessage = "Notitie opslaan mislukt: \(error.localizedDescription)"
        }
    }

    func clearActiveSession() {
        activeSession = nil
        sessionExercises = []
        sessionSets = []
        sessionTargets = [:]
        previousSummaries = [:]
    }

    // MARK: - Referenties

    private func loadPreviousSummaries(before dateIso: String) async {
        for exercise in sessionExercises {
            await loadPreviousSummary(exerciseId: exercise.id, before: dateIso)
        }
    }

    private func loadPreviousSummary(exerciseId: UUID, before dateIso: String) async {
        guard previousSummaries[exerciseId] == nil else { return }
        if let summary = try? await workoutRepository.fetchPreviousSets(exerciseId: exerciseId, before: dateIso) {
            previousSummaries[exerciseId] = summary
        }
    }
}
