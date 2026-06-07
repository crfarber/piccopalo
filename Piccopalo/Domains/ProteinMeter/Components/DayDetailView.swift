import SwiftUI

struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountViewModel: AccountViewModel
    @EnvironmentObject private var proteinViewModel: ProteinViewModel
    @FocusState private var gramsFieldFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var currentRecord: DayRecord
    @State private var proteinConsumedInput: String

    init(record: DayRecord) {
        _currentRecord = State(initialValue: record)
        _proteinConsumedInput = State(initialValue: String(format: "%.0f", record.proteinConsumed))
    }

    private var effectiveWeight: Double {
        let fromAccount = Double(accountViewModel.weight) ?? 0
        if fromAccount > 0 { return fromAccount }
        return currentRecord.weight
    }

    private var percentage: Double {
        guard currentRecord.proteinGoal > 0 else { return 0 }
        return min((currentRecord.proteinConsumed / currentRecord.proteinGoal) * 100, 100)
    }

    private var displayPercentageWhole: Int {
        Int(round(percentage))
    }

    private var navigationTitleDate: String {
        guard let date = HistoryFormatting.date(fromISODate: currentRecord.date) else {
            return currentRecord.date
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }

    private var resultStatus: String {
        if currentRecord.proteinConsumed >= currentRecord.proteinGoal, currentRecord.proteinGoal > 0 {
            return "Doel gehaald"
        }
        if currentRecord.proteinGoal <= 0 {
            return "Stel gewicht en activiteit in"
        }
        return "Nog niet gehaald"
    }

    private var resultStatusColor: Color {
        if currentRecord.proteinConsumed >= currentRecord.proteinGoal, currentRecord.proteinGoal > 0 {
            return Theme.Colors.green
        }
        return Theme.Colors.textMuted
    }

    private var heroPercentSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 36
        case .large, .xLarge, .xxLarge:
            return 34
        default:
            return 30
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                detailHeader
                    .padding(.top, Theme.Spacing.sm)

                resultCard

                gegevensSection

                mealEntriesSection

                manualSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Theme.Colors.background)
        .navigationBarHidden(true)
        .onAppear {
            let weight = effectiveWeight
            guard weight > 0 else { return }
            let newGoal = weight * currentRecord.activityFactor
            if abs(currentRecord.weight - weight) > 0.01 || abs(currentRecord.proteinGoal - newGoal) > 0.01 {
                currentRecord.weight = weight
                currentRecord.proteinGoal = newGoal
                persistRecord()
            }
        }
        .onDisappear {
            if currentRecord.date == proteinViewModel.today {
                Task { await proteinViewModel.refresh() }
            }
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .center) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Terug")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.green)
                }
                .accessibilityLabel("Terug")

                Spacer()

                Button {
                    gramsFieldFocused = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.Colors.text)
                }
                .accessibilityLabel("Handmatig aanpassen")
            }

            Text(navigationTitleDate)
                .font(.custom(Theme.Typography.displayFont, size: 28, relativeTo: .title2))
                .foregroundStyle(Theme.Colors.cream)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var resultCard: some View {
        StyledCard {
            HStack(alignment: .center, spacing: Theme.Spacing.lg) {
                ProgressBar(percentage: percentage, size: 72, showGlow: true)
                    .frame(width: 72, height: 86)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Resultaat")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .tracking(0.4)
                        .textCase(.uppercase)

                    Text("\(displayPercentageWhole)%")
                        .font(.custom(Theme.Typography.displayFont, size: heroPercentSize, relativeTo: .title))
                        .foregroundStyle(Theme.Colors.text)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    Text(resultStatus)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(resultStatusColor)

                    Text("\(grams(currentRecord.proteinConsumed))g van \(grams(currentRecord.proteinGoal))g")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var gegevensSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel("Gegevens", icon: "person.fill")

            StyledCard {
                VStack(spacing: 0) {
                    rowLabelLeftValueRight(label: "Gewicht", value: "\(String(format: "%.0f", effectiveWeight)) kg")

                    Divider()
                        .background(Color.white.opacity(0.08))

                    HStack(alignment: .center) {
                        Text("Activiteit")
                            .foregroundStyle(Theme.Colors.textMuted)
                            .font(.system(size: 15, weight: .regular))

                        Spacer(minLength: Theme.Spacing.sm)

                        Picker("", selection: activityFactorBinding) {
                            ForEach(accountViewModel.activityOptions, id: \.factor) { option in
                                Text("\(option.label) (\(trimFactor(option.factor)))")
                                    .tag(option.factor)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.Colors.cream)
                        .accessibilityLabel("Activiteit")
                    }
                    .padding(.vertical, Theme.Spacing.md)

                    Divider()
                        .background(Color.white.opacity(0.08))

                    rowLabelLeftValueRight(label: "Eiwitdoel", value: "\(grams(currentRecord.proteinGoal))g")
                }
            }
        }
    }

    private var activityFactorBinding: Binding<Double> {
        Binding(
            get: { currentRecord.activityFactor },
            set: { newValue in
                currentRecord.activityFactor = newValue
                syncGoalAndPersist()
            }
        )
    }

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel("Handmatig aanpassen", icon: "square.and.pencil")

            StyledCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Pas alleen deze dag aan. Je kunt fouten achteraf corrigeren.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                        TextInput(
                            label: "",
                            text: $proteinConsumedInput,
                            placeholder: "Gegeten gram",
                            unit: nil,
                            keyboard: .decimal,
                            fieldFocus: $gramsFieldFocused
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        AppButton(
                            title: "Opslaan",
                            icon: nil,
                            size: .medium,
                            background: Theme.Colors.cream,
                            foreground: Color(red: 0.1, green: 0.1, blue: 0.1),
                            cornerStyle: .rounded(Theme.Radius.md),
                            action: saveManualGrams
                        )
                    }
                }
            }
        }
    }

    private var mealEntriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel("Innames", icon: "list.bullet")

            StyledCard {
                if currentRecord.entries.isEmpty {
                    Text("Nog geen losse innames opgeslagen voor deze dag.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.Spacing.sm)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(currentRecord.entries.enumerated()), id: \.element.id) { index, entry in
                            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.sourceName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.Colors.text)

                                    Text("\(quantity(entry.quantity))\(entry.unit.symbol) -> \(quantity(entry.proteinAmount))g eiwit")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.Colors.textMuted)
                                }

                                Spacer(minLength: Theme.Spacing.sm)

                                Button {
                                    removeEntry(entry)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.Colors.tomato)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Verwijder inname")
                            }
                            .padding(.vertical, Theme.Spacing.md)

                            if index < currentRecord.entries.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.08))
                            }
                        }
                    }
                }
            }
        }
    }

    private func rowLabelLeftValueRight(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.Colors.textMuted)
                .font(.system(size: 15, weight: .regular))
            Spacer()
            Text(value)
                .foregroundStyle(Theme.Colors.text)
                .font(.system(size: 17, weight: .semibold))
                .monospacedDigit()
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    private func trimFactor(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func grams(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func quantity(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func syncGoalAndPersist() {
        let w = effectiveWeight
        currentRecord.weight = w
        currentRecord.proteinGoal = w * currentRecord.activityFactor
        persistRecord()
    }

    private func saveManualGrams() {
        guard let value = Double(proteinConsumedInput.replacingOccurrences(of: ",", with: ".")), value >= 0 else { return }
        currentRecord.proteinConsumed = value
        currentRecord.entries = value > 0
            ? [
                ProteinEntry(
                    sourceName: "Handmatige correctie",
                    quantity: value,
                    unit: .grams,
                    proteinPer100: 100,
                    proteinAmount: value
                )
            ]
            : []
        proteinConsumedInput = String(format: "%.0f", value)
        persistRecord()
    }

    private func removeEntry(_ entry: ProteinEntry) {
        currentRecord.entries.removeAll { $0.id == entry.id }
        currentRecord.proteinConsumed = max(0, currentRecord.entries.reduce(0) { $0 + $1.proteinAmount })
        proteinConsumedInput = String(format: "%.0f", currentRecord.proteinConsumed)
        persistRecord()
    }

    private func persistRecord() {
        proteinViewModel.saveDayRecord(currentRecord)
    }
}

