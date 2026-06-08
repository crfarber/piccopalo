import SwiftUI

struct WorkoutSessionView: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel
    @StateObject private var rustTimer = RustTimerManager()
    @Binding var path: [FitnessRoute]

    @State private var showExercisePicker = false
    @State private var showRestSheet = false
    @State private var showFinishConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                header

                ForEach(fitnessViewModel.sessionExercises) { exercise in
                    ExerciseSessionCard(
                        exercise: exercise,
                        sets: fitnessViewModel.sets(for: exercise.id),
                        previous: fitnessViewModel.previousSummaries[exercise.id],
                        target: fitnessViewModel.target(for: exercise.id),
                        onLogSet: { reps, weight, rest in
                            Task {
                                await fitnessViewModel.logSet(
                                    exerciseId: exercise.id,
                                    reps: reps,
                                    weightKg: weight,
                                    restSeconds: rest
                                )
                                if let rest, rest > 0 {
                                    rustTimer.start(seconds: rest)
                                    showRestSheet = true
                                }
                            }
                        },
                        onDeleteSet: { set in
                            Task { await fitnessViewModel.deleteSet(set) }
                        },
                        onStartRest: { seconds in
                            rustTimer.start(seconds: seconds)
                            showRestSheet = true
                        }
                    )
                }

                addExerciseButton
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "Training afronden",
                icon: "flag.checkered",
                action: { showFinishConfirm = true },
                color: Theme.Colors.green
            )
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.background)
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(
                excludedIds: Set(fitnessViewModel.sessionExercises.map { $0.id })
            ) { chosen in
                Task {
                    for exercise in chosen {
                        await fitnessViewModel.addExerciseToSession(exercise)
                    }
                }
            }
        }
        .sheet(isPresented: $showRestSheet) {
            RestTimerSheet(timer: rustTimer)
                .adaptiveBottomSheet()
        }
        .confirmationDialog(
            finishMessage,
            isPresented: $showFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Training opslaan") { finish() }
            Button("Annuleer", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        StyledCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Verstreken tijd")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.4)
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(elapsedLabel)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                            .monospacedDigit()
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(fitnessViewModel.sessionSets.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.Colors.green)
                        .monospacedDigit()
                    Text("sets")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
    }

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            StyledCard {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.Colors.green)
                    Text("Oefening toevoegen")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var elapsedLabel: String {
        let seconds = fitnessViewModel.activeSession?.elapsedSeconds ?? 0
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private var finishMessage: String {
        let count = fitnessViewModel.sessionSets.count
        return count == 1 ? "Je hebt 1 set gelogd." : "Je hebt \(count) sets gelogd."
    }

    private func finish() {
        rustTimer.stop()
        Task {
            await fitnessViewModel.finishSession(note: nil)
            path.append(.summary)
        }
    }
}

// MARK: - Exercise card

private struct ExerciseSessionCard: View {
    let exercise: Exercise
    let sets: [WorkoutSet]
    let previous: PreviousSetSummary?
    let target: WorkoutTemplateExercise?
    let onLogSet: (Int?, Double?, Int?) -> Void
    let onDeleteSet: (WorkoutSet) -> Void
    let onStartRest: (Int) -> Void

    @State private var repsText = ""
    @State private var weightText = ""

    private var restSeconds: Int {
        target?.targetRestSeconds ?? 90
    }

    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(exercise.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                referenceBanner

                if !sets.isEmpty {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(sets) { set in
                            LoggedSetRow(set: set, onDelete: { onDeleteSet(set) })
                        }
                    }
                }

                inputRow
            }
        }
    }

    private var referenceBanner: some View {
        Group {
            if let previous {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                    Text("Vorige keer (\(shortDate(previous.dateIso))): \(previous.setsLabel)")
                        .font(.system(size: 13))
                        .lineLimit(2)
                }
                .foregroundColor(Theme.Colors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface2)
                .cornerRadius(Theme.Radius.sm)
            } else {
                Text("Eerste keer deze oefening")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textDim)
            }
        }
    }

    private var inputRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            compactField(text: $weightText, placeholder: "kg", keyboard: .decimalPad)
            compactField(text: $repsText, placeholder: "reps", keyboard: .numberPad)

            Button {
                logSet()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.green)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onStartRest(restSeconds)
            } label: {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func compactField(text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(Theme.Colors.textDim))
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Theme.Colors.text)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }

    private func logSet() {
        let reps = Int(repsText.trimmingCharacters(in: .whitespaces))
        let weight = Double(weightText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        guard reps != nil || weight != nil else { return }
        onLogSet(reps, weight, restSeconds)
        repsText = ""
        weightText = ""
    }

    private func shortDate(_ iso: String) -> String {
        guard let date = DayFormatting.date(fromISODate: iso) else { return iso }
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"
        return formatter
    }()
}

private struct LoggedSetRow: View {
    let set: WorkoutSet
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("Set \(set.setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
                .frame(width: 54, alignment: .leading)

            Text(valueLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .monospacedDigit()

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Theme.Colors.surface2)
        .cornerRadius(Theme.Radius.sm)
    }

    private var valueLabel: String {
        let weightPart = set.weightKg.map { "\(PreviousSetSummary.formatKg($0)) kg" }
        let repsPart = set.reps.map { "\($0) reps" }
        return [weightPart, repsPart].compactMap { $0 }.joined(separator: " × ")
    }
}

// MARK: - Rest timer sheet

private struct RestTimerSheet: View {
    @ObservedObject var timer: RustTimerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            SectionLabel("Rust", icon: "timer")

            ZStack {
                Circle()
                    .stroke(Theme.Colors.surface2, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(Theme.Colors.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                Text("\(timer.secondsRemaining)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                    .monospacedDigit()
            }
            .frame(width: 160, height: 160)
            .padding(.vertical, Theme.Spacing.md)

            PrimaryButton(
                title: timer.isRunning ? "Overslaan" : "Klaar",
                icon: timer.isRunning ? "forward.fill" : "checkmark.circle.fill",
                action: {
                    timer.stop()
                    dismiss()
                },
                color: Theme.Colors.green
            )
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .adaptiveSheetContentHeight()
        .background(Theme.Colors.background)
        .onChange(of: timer.isRunning) { _, running in
            if !running { dismiss() }
        }
    }
}
