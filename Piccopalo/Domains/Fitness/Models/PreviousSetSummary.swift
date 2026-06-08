import Foundation

/// Samenvatting van de vorige keer dat een oefening werd gedaan, voor de referentie-banner.
struct PreviousSetSummary {
    let exerciseId: UUID
    let exerciseName: String
    let dateIso: String
    let sets: [WorkoutSet]

    /// Zwaarste set van die sessie.
    var bestSet: WorkoutSet? {
        sets.max { ($0.weightKg ?? 0) < ($1.weightKg ?? 0) }
    }

    /// Compacte samenvatting van alle sets, bijv. "60×8, 65×6".
    var setsLabel: String {
        let parts = sets.map { set -> String in
            let kg = set.weightKg.map { Self.formatKg($0) } ?? "?"
            let reps = set.reps.map { String($0) } ?? "?"
            return "\(kg)×\(reps)"
        }
        return parts.joined(separator: ", ")
    }

    static func formatKg(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
