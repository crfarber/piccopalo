import Foundation

/// Eén uitgevoerde training. `templateId` nil = vrij gelogd.
struct WorkoutSession: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let dateIso: String          // "yyyy-MM-dd"
    let templateId: UUID?
    var startedAt: Date?
    var finishedAt: Date?
    var note: String?

    init(
        id: UUID = UUID(),
        userId: UUID,
        dateIso: String,
        templateId: UUID? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.dateIso = dateIso
        self.templateId = templateId
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.note = note
    }

    var isFinished: Bool { finishedAt != nil }

    /// Duur in seconden tussen start en einde (of nu, als nog bezig).
    var elapsedSeconds: Int {
        guard let start = startedAt else { return 0 }
        let end = finishedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(start)))
    }
}
