import SwiftUI

struct SymptomLogView: View {
    var dateIso: String?
    @EnvironmentObject var healthViewModel: HealthViewModel

    @State private var energy = 3
    @State private var focus = 3
    @State private var hunger = 3
    @State private var note = ""
    @State private var savedConfirmation = false

    private var targetDateIso: String {
        dateIso ?? healthViewModel.today
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                inputCard
                if savedConfirmation {
                    confirmationBanner
                }
                entriesCard
            }
            .padding(.vertical, Theme.Spacing.lg)
            .adaptiveSheetContentHeight()
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Hoe voel je je?")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task { await healthViewModel.loadSymptoms(for: targetDateIso) }
        .alert(
            "Opslaan mislukt",
            isPresented: Binding(
                get: { healthViewModel.errorMessage != nil },
                set: { if !$0 { healthViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { healthViewModel.errorMessage = nil }
        } message: {
            Text(healthViewModel.errorMessage ?? "")
        }
    }

    // MARK: - Input card

    private var inputCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                emojiSelector(.energy, level: $energy)
                emojiSelector(.focus, level: $focus)
                emojiSelector(.hunger, level: $hunger)

                TextInput(
                    label: "Notitie",
                    text: $note,
                    placeholder: "Iets bijzonders vandaag?",
                    keyboard: .text
                )

                PrimaryButton(
                    title: "Vastleggen",
                    icon: "checkmark.circle.fill",
                    action: save,
                    color: Theme.Colors.green
                )
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func emojiSelector(_ dimension: SymptomDimension, level: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(dimension.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    let isActive = level.wrappedValue == value
                    Button {
                        level.wrappedValue = value
                    } label: {
                        Text(dimension.emoji(for: value))
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                    .fill(isActive ? Theme.Colors.green.opacity(0.18) : Theme.Colors.surface2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                    .stroke(Theme.Colors.green.opacity(isActive ? 0.7 : 0), lineWidth: 1.2)
                            )
                            .opacity(isActive ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var confirmationBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.green)
            Text("Vastgelegd ✓")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.green.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .padding(.horizontal, Theme.Spacing.lg)
        .transition(.opacity)
    }

    // MARK: - Entries card

    private var entriesCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Vandaag", icon: "list.bullet")

                if healthViewModel.todaysSymptoms.isEmpty {
                    Text("Nog niets vastgelegd vandaag")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.Spacing.sm)
                } else {
                    ForEach(healthViewModel.todaysSymptoms) { entry in
                        SymptomRow(entry: entry) {
                            Task { await healthViewModel.deleteSymptom(entry) }
                        }
                        if entry.id != healthViewModel.todaysSymptoms.last?.id {
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Actions

    private func save() {
        let capturedEnergy = energy
        let capturedFocus = focus
        let capturedHunger = hunger
        let capturedNote = note

        Task {
            await healthViewModel.saveSymptom(
                energy: capturedEnergy,
                focus: capturedFocus,
                hunger: capturedHunger,
                note: capturedNote,
                dateIso: targetDateIso
            )
            await healthViewModel.loadSymptoms(for: targetDateIso)
            await MainActor.run {
                withAnimation { savedConfirmation = true }
                note = ""
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { savedConfirmation = false }
            }
        }
    }
}

private struct SymptomRow: View {
    let entry: SymptomEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Theme.Spacing.md) {
                    if let energy = entry.energyLevel {
                        Text(SymptomDimension.energy.emoji(for: energy))
                            .font(.system(size: 20))
                    }
                    if let focus = entry.focusLevel {
                        Text(SymptomDimension.focus.emoji(for: focus))
                            .font(.system(size: 20))
                    }
                    if let hunger = entry.hungerLevel {
                        Text(SymptomDimension.hunger.emoji(for: hunger))
                            .font(.system(size: 20))
                    }
                    Text(Self.timeFormatter.string(from: entry.recordedAt))
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textDim)
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(Theme.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()
}
