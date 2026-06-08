import SwiftUI

struct BloodSugarLogView: View {
    var dateIso: String?
    @EnvironmentObject var healthViewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var valueText = ""
    @State private var selectedMoment: BSMoment = .willekeurig
    @State private var note = ""
    @State private var savedConfirmation: String?
    @FocusState private var isValueFocused: Bool

    private var valueMmol: Double {
        let normalized = valueText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var canSave: Bool {
        valueMmol > 0
    }

    private var targetDateIso: String {
        dateIso ?? healthViewModel.today
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                inputCard
                if let savedConfirmation {
                    confirmationBanner(savedConfirmation)
                }
                readingsCard
            }
            .padding(.vertical, Theme.Spacing.lg)
            .adaptiveSheetContentHeight()
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Bloedsuiker opnemen")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task { await healthViewModel.loadReadings(for: targetDateIso) }
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
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Nieuwe meting", icon: "drop.fill")

                TextInput(
                    label: "Waarde (mmol/L)",
                    text: $valueText,
                    placeholder: "bijv. 7.2",
                    unit: "mmol/L",
                    keyboard: .decimal,
                    fieldFocus: $isValueFocused
                )
                .onChange(of: valueText) {
                    let normalized = valueText.replacingOccurrences(of: ",", with: ".")
                    let filtered = normalized.filter { "0123456789.".contains($0) }
                    if filtered != normalized {
                        valueText = filtered
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Moment")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)

                    momentSelector
                }

                TextInput(
                    label: "Notitie",
                    text: $note,
                    placeholder: "Optioneel – hoe voel je je?",
                    keyboard: .text
                )

                PrimaryButton(
                    title: "Opslaan",
                    icon: "checkmark.circle.fill",
                    action: save,
                    color: Theme.Colors.green,
                    isDisabled: !canSave
                )
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var momentSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(BSMoment.allCases) { moment in
                    Pill(
                        title: moment.label,
                        isActive: selectedMoment == moment,
                        action: { selectedMoment = moment }
                    )
                }
            }
        }
    }

    private func confirmationBanner(_ text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.green)
            Text(text)
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

    // MARK: - Readings card

    private var readingsCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Vandaag", icon: "list.bullet")

                if healthViewModel.todaysReadings.isEmpty {
                    Text("Nog geen metingen vandaag")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.Spacing.sm)
                } else {
                    ForEach(healthViewModel.todaysReadings) { reading in
                        BloodSugarRow(reading: reading) {
                            Task { await healthViewModel.deleteBloodSugar(reading) }
                        }
                        if reading.id != healthViewModel.todaysReadings.last?.id {
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
        guard canSave else { return }
        isValueFocused = false
        let capturedValue = valueMmol
        let capturedMoment = selectedMoment
        let capturedNote = note

        Task {
            await healthViewModel.saveBloodSugar(
                valueMmol: capturedValue,
                moment: capturedMoment,
                note: capturedNote,
                dateIso: targetDateIso
            )
            await healthViewModel.loadReadings(for: targetDateIso)
            await MainActor.run {
                let timeString = Self.timeFormatter.string(from: Date())
                withAnimation { savedConfirmation = "Opgeslagen om \(timeString)" }
                valueText = ""
                note = ""
                selectedMoment = .willekeurig
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { savedConfirmation = nil }
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()
}

private struct BloodSugarRow: View {
    let reading: BloodSugarEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f", reading.valueMmol))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    + Text(" mmol/L")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(Self.timeFormatter.string(from: reading.recordedAt))
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textMuted)
                    if let moment = reading.moment {
                        Text("· \(moment.label)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                }

                if let note = reading.note, !note.isEmpty {
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
