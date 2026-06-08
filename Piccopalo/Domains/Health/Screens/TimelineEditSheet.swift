import SwiftUI

struct TimelineEditItem: Identifiable {
    let event: TimelineEvent
    var id: String { event.id }
}

struct TimelineEditSheet: View {
    let item: TimelineEditItem
    let dateIso: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proteinViewModel: ProteinViewModel
    @EnvironmentObject private var healthViewModel: HealthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    switch item.event {
                    case .meal(let entry):
                        MealEditForm(entry: entry, dateIso: dateIso, onSaved: finish)
                    case .water(let entry):
                        WaterEditForm(entry: entry, dateIso: dateIso, onSaved: finish)
                    case .bloodSugar(let entry):
                        BloodSugarEditForm(entry: entry, onSaved: finish)
                    case .symptom(let entry):
                        SymptomEditForm(entry: entry, onSaved: finish)
                    }
                }
                .padding(Theme.Spacing.lg)
                .adaptiveSheetContentHeight()
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
            }
        }
    }

    private func finish() {
        onSaved()
        dismiss()
    }
}

// MARK: - Manual protein add

struct ManualProteinSheet: View {
    let dateIso: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proteinViewModel: ProteinViewModel
    @State private var nameText = "Handmatig"
    @State private var gramsText = ""
    @FocusState private var isGramsFocused: Bool

    private var grams: Double {
        Double(gramsText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            StyledCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionLabel("Eiwit toevoegen", icon: "fork.knife")

                    TextInput(
                        label: "Naam",
                        text: $nameText,
                        placeholder: "bijv. Handmatig",
                        keyboard: .text
                    )

                    TextInput(
                        label: "Eiwit (gram)",
                        text: $gramsText,
                        placeholder: "bijv. 25",
                        unit: "g",
                        keyboard: .decimal,
                        fieldFocus: $isGramsFocused
                    )

                    PrimaryButton(
                        title: "Toevoegen",
                        icon: "plus.circle.fill",
                        action: save,
                        color: Theme.Colors.green,
                        isDisabled: grams <= 0
                    )
                }
            }
            .padding(Theme.Spacing.lg)
            .adaptiveSheetContentHeight()
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Handmatig eiwit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard grams > 0 else { return }
        isGramsFocused = false
        Task {
            await proteinViewModel.addManualProtein(grams: grams, to: dateIso, sourceName: nameText)
            await MainActor.run {
                onSaved()
                dismiss()
            }
        }
    }
}

// MARK: - Manual water add

struct ManualWaterSheet: View {
    let dateIso: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proteinViewModel: ProteinViewModel
    @State private var mlText = ""
    @FocusState private var isFocused: Bool

    private let quickAmounts = [200, 250, 500]

    private var milliliters: Int {
        Int(mlText.filter { $0.isNumber }) ?? 0
    }

    var body: some View {
        NavigationStack {
            StyledCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionLabel("Water toevoegen", icon: "waterbottle.fill")

                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                mlText = String(amount)
                            } label: {
                                Text("\(amount) ml")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(milliliters == amount ? Theme.Colors.background : Theme.Colors.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                            .fill(milliliters == amount ? Theme.Colors.blue : Theme.Colors.surface2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextInput(
                        label: "Aangepast (ml)",
                        text: $mlText,
                        placeholder: "bijv. 300",
                        unit: "ml",
                        keyboard: .integer,
                        fieldFocus: $isFocused
                    )

                    PrimaryButton(
                        title: "Toevoegen",
                        icon: "plus.circle.fill",
                        action: save,
                        color: Theme.Colors.green,
                        isDisabled: milliliters <= 0
                    )
                }
            }
            .padding(Theme.Spacing.lg)
            .adaptiveSheetContentHeight()
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard milliliters > 0 else { return }
        isFocused = false
        Task {
            try? await proteinViewModel.addWaterEntry(milliliters: milliliters, to: dateIso)
            await MainActor.run {
                onSaved()
                dismiss()
            }
        }
    }
}

// MARK: - Add options bottom sheet

enum AddOptionKind {
    case water
    case protein
    case bloodSugar
    case symptom
}

struct AddOptionsSheet: View {
    let onSelect: (AddOptionKind) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Toevoegen")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.sm) {
                optionRow(icon: "waterbottle.fill", color: Theme.Colors.blue, title: "Water", subtitle: "Hydratatie loggen") {
                    onSelect(.water)
                }
                optionRow(icon: "fork.knife", color: Theme.Colors.green, title: "Eiwit", subtitle: "Handmatige inname") {
                    onSelect(.protein)
                }
                optionRow(icon: "drop.fill", color: Theme.Colors.tomato, title: "Bloedsuiker", subtitle: "Meting opnemen") {
                    onSelect(.bloodSugar)
                }
                optionRow(icon: "face.smiling", color: Theme.Colors.cream, title: "Gevoel", subtitle: "Energie, focus, honger") {
                    onSelect(.symptom)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .adaptiveSheetContentHeight()
    }

    private func optionRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(color.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Meal edit

private struct MealEditForm: View {
    let entry: ProteinEntry
    let dateIso: String
    let onSaved: () -> Void

    @EnvironmentObject private var proteinViewModel: ProteinViewModel
    @State private var nameText: String
    @State private var quantityText: String

    init(entry: ProteinEntry, dateIso: String, onSaved: @escaping () -> Void) {
        self.entry = entry
        self.dateIso = dateIso
        self.onSaved = onSaved
        _nameText = State(initialValue: entry.sourceName)
        _quantityText = State(initialValue: Self.formatQuantity(entry.quantity))
    }

    private var quantity: Double {
        Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                TextInput(label: "Naam", text: $nameText, placeholder: "Bron", keyboard: .text)

                TextInput(
                    label: "Hoeveelheid (\(entry.unit.symbol))",
                    text: $quantityText,
                    placeholder: "Hoeveelheid",
                    unit: entry.unit.symbol,
                    keyboard: .decimal
                )

                if entry.proteinPer100 != 100 || entry.unit != .grams {
                    Text(String(format: "≈ %.0fg eiwit bij deze hoeveelheid", (quantity / 100) * entry.proteinPer100))
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                PrimaryButton(
                    title: "Opslaan",
                    icon: "checkmark.circle.fill",
                    action: save,
                    color: Theme.Colors.green,
                    isDisabled: quantity <= 0
                )
            }
        }
    }

    private func save() {
        guard quantity > 0 else { return }
        Task {
            await proteinViewModel.updateProteinEntry(
                id: entry.id,
                in: dateIso,
                sourceName: nameText,
                quantity: quantity
            )
            await MainActor.run { onSaved() }
        }
    }

    private static func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}

// MARK: - Water edit

private struct WaterEditForm: View {
    let entry: WaterEntry
    let dateIso: String
    let onSaved: () -> Void

    @EnvironmentObject private var proteinViewModel: ProteinViewModel
    @State private var millilitersText: String

    init(entry: WaterEntry, dateIso: String, onSaved: @escaping () -> Void) {
        self.entry = entry
        self.dateIso = dateIso
        self.onSaved = onSaved
        _millilitersText = State(initialValue: String(entry.milliliters))
    }

    private var milliliters: Int {
        Int(millilitersText.filter { $0.isNumber }) ?? 0
    }

    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                TextInput(
                    label: "Water (ml)",
                    text: $millilitersText,
                    placeholder: "bijv. 250",
                    unit: "ml",
                    keyboard: .integer
                )

                PrimaryButton(
                    title: "Opslaan",
                    icon: "checkmark.circle.fill",
                    action: save,
                    color: Theme.Colors.green,
                    isDisabled: milliliters <= 0
                )
            }
        }
    }

    private func save() {
        guard milliliters > 0 else { return }
        Task {
            try? await proteinViewModel.updateWaterEntry(entry, milliliters: milliliters, on: dateIso)
            await MainActor.run { onSaved() }
        }
    }
}

// MARK: - Blood sugar edit

private struct BloodSugarEditForm: View {
    let entry: BloodSugarEntry
    let onSaved: () -> Void

    @EnvironmentObject private var healthViewModel: HealthViewModel
    @State private var valueText: String
    @State private var selectedMoment: BSMoment
    @State private var note: String

    init(entry: BloodSugarEntry, onSaved: @escaping () -> Void) {
        self.entry = entry
        self.onSaved = onSaved
        _valueText = State(initialValue: String(format: "%.1f", entry.valueMmol))
        _selectedMoment = State(initialValue: entry.moment ?? .willekeurig)
        _note = State(initialValue: entry.note ?? "")
    }

    private var valueMmol: Double {
        Double(valueText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                TextInput(
                    label: "Waarde (mmol/L)",
                    text: $valueText,
                    placeholder: "bijv. 7.2",
                    unit: "mmol/L",
                    keyboard: .decimal
                )

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Moment")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)

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

                TextInput(label: "Notitie", text: $note, placeholder: "Optioneel", keyboard: .text)

                PrimaryButton(
                    title: "Opslaan",
                    icon: "checkmark.circle.fill",
                    action: save,
                    color: Theme.Colors.green,
                    isDisabled: valueMmol <= 0
                )
            }
        }
    }

    private func save() {
        guard valueMmol > 0 else { return }
        Task {
            await healthViewModel.updateBloodSugar(
                entry,
                valueMmol: valueMmol,
                moment: selectedMoment,
                note: note
            )
            await MainActor.run { onSaved() }
        }
    }
}

// MARK: - Symptom edit

private struct SymptomEditForm: View {
    let entry: SymptomEntry
    let onSaved: () -> Void

    @EnvironmentObject private var healthViewModel: HealthViewModel
    @State private var energy: Int
    @State private var focus: Int
    @State private var hunger: Int
    @State private var note: String

    init(entry: SymptomEntry, onSaved: @escaping () -> Void) {
        self.entry = entry
        self.onSaved = onSaved
        _energy = State(initialValue: entry.energyLevel ?? 3)
        _focus = State(initialValue: entry.focusLevel ?? 3)
        _hunger = State(initialValue: entry.hungerLevel ?? 3)
        _note = State(initialValue: entry.note ?? "")
    }

    var body: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                symptomSelector(.energy, level: $energy)
                symptomSelector(.focus, level: $focus)
                symptomSelector(.hunger, level: $hunger)

                TextInput(label: "Notitie", text: $note, placeholder: "Optioneel", keyboard: .text)

                PrimaryButton(
                    title: "Opslaan",
                    icon: "checkmark.circle.fill",
                    action: save,
                    color: Theme.Colors.green
                )
            }
        }
    }

    private func symptomSelector(_ dimension: SymptomDimension, level: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(dimension.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    let isActive = level.wrappedValue == value
                    Button { level.wrappedValue = value } label: {
                        Text(dimension.emoji(for: value))
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                    .fill(isActive ? Theme.Colors.green.opacity(0.18) : Theme.Colors.surface2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        Task {
            await healthViewModel.updateSymptom(
                entry,
                energy: energy,
                focus: focus,
                hunger: hunger,
                note: note
            )
            await MainActor.run { onSaved() }
        }
    }
}
