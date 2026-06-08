import Foundation

/// Eén gelogde set binnen een sessie.
struct WorkoutSet: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: UUID
    let exerciseId: UUID
    var setNumber: Int
    var reps: Int?
    var weightKg: Double?
    var restSeconds: Int?
    var note: String?
    var loggedAt: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        exerciseId: UUID,
        setNumber: Int,
        reps: Int? = nil,
        weightKg: Double? = nil,
        restSeconds: Int? = nil,
        note: String? = nil,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.restSeconds = restSeconds
        self.note = note
        self.loggedAt = loggedAt
    }

    /// Volume van deze set (kg × reps), 0 als een waarde ontbreekt.
    var volume: Double {
        (weightKg ?? 0) * Double(reps ?? 0)
    }
}
