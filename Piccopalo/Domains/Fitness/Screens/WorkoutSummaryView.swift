import SwiftUI

struct WorkoutSummaryView: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel
    @Binding var path: [FitnessRoute]

    @State private var note = ""

    private var sets: [WorkoutSet] { fitnessViewModel.sessionSets }

    private var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    private var exercisesWithSets: [Exercise] {
        fitnessViewModel.sessionExercises.filter { exercise in
            sets.contains { $0.exerciseId == exercise.id }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                headerCard
                statsCard
                if !exercisesWithSets.isEmpty {
                    exercisesCard
                }
                noteCard
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Samenvatting")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "Klaar",
                icon: "checkmark.circle.fill",
                action: done,
                color: Theme.Colors.green
            )
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.background)
        }
        .onAppear {
            note = fitnessViewModel.activeSession?.note ?? ""
        }
    }

    private var headerCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Goed gedaan!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                Text("Je training is opgeslagen.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statsCard: some View {
        StyledCard {
            HStack {
                statBlock(value: durationLabel, label: "Duur")
                Divider().frame(height: 40).overlay(Color.white.opacity(0.08))
                statBlock(value: "\(exercisesWithSets.count)", label: "Oefeningen")
                Divider().frame(height: 40).overlay(Color.white.opacity(0.08))
                statBlock(value: "\(sets.count)", label: "Sets")
            }
        }
    }

    private var exercisesCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Per oefening", icon: "list.bullet")
                Text("Totaal volume: \(PreviousSetSummary.formatKg(totalVolume)) kg")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)

                ForEach(exercisesWithSets) { exercise in
                    ExerciseSummaryRow(
                        name: exercise.name,
                        best: bestSet(for: exercise.id),
                        previousBest: fitnessViewModel.previousSummaries[exercise.id]?.bestSet
                    )
                    if exercise.id != exercisesWithSets.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
        }
    }

    private var noteCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionLabel("Notitie", icon: "square.and.pencil")
                TextField(
                    "",
                    text: $note,
                    prompt: Text("Hoe voelde deze training?").foregroundColor(Theme.Colors.textDim),
                    axis: .vertical
                )
                .lineLimit(2...4)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.text)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface2)
                .cornerRadius(Theme.Radius.sm)
            }
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.text)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var durationLabel: String {
        let seconds = fitnessViewModel.activeSession?.elapsedSeconds ?? 0
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    private func bestSet(for exerciseId: UUID) -> WorkoutSet? {
        sets.filter { $0.exerciseId == exerciseId }
            .max { ($0.weightKg ?? 0) < ($1.weightKg ?? 0) }
    }

    private func done() {
        Task {
            await fitnessViewModel.saveSessionNote(note)
            fitnessViewModel.clearActiveSession()
            path.removeAll()
        }
    }
}

private struct ExerciseSummaryRow: View {
    let name: String
    let best: WorkoutSet?
    let previousBest: WorkoutSet?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(bestLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .monospacedDigit()
                    if let trend {
                        Image(systemName: trend.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(trend.color)
                    }
                }
                if let previousLabel {
                    Text(previousLabel)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var bestLabel: String {
        guard let best else { return "—" }
        let weightPart = best.weightKg.map { "\(PreviousSetSummary.formatKg($0)) kg" }
        let repsPart = best.reps.map { "\($0)" }
        return [weightPart, repsPart].compactMap { $0 }.joined(separator: " × ")
    }

    private var previousLabel: String? {
        guard let previousBest else { return nil }
        let weightPart = previousBest.weightKg.map { "\(PreviousSetSummary.formatKg($0)) kg" }
        let repsPart = previousBest.reps.map { "\($0)" }
        let label = [weightPart, repsPart].compactMap { $0 }.joined(separator: " × ")
        return label.isEmpty ? nil : "was \(label)"
    }

    private enum Trend {
        case increased, steady

        var icon: String {
            switch self {
            case .increased: return "arrow.up"
            case .steady: return "arrow.left.and.right"
            }
        }

        var color: Color {
            switch self {
            case .increased: return Theme.Colors.green
            case .steady: return Theme.Colors.textMuted
            }
        }
    }

    private var trend: Trend? {
        guard let current = best?.weightKg, let previous = previousBest?.weightKg else { return nil }
        if current > previous { return .increased }
        if current == previous { return .steady }
        return nil
    }
}
