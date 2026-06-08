import SwiftUI

struct DayTimelineView: View {
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @EnvironmentObject var healthViewModel: HealthViewModel
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var accountViewModel: AccountViewModel
    @State private var selectedDate = Date()
    @State private var dayRecord: DayRecord?
    @State private var waterConsumedMl: Double = 0
    @State private var daySteps: Int?
    @State private var events: [TimelineEvent] = []
    @State private var weekRecords: [DayRecord] = []
    @State private var isLoading = false
    @State private var showAddOptions = false
    @State private var pendingAdd: AddSheet?
    @State private var activeSheet: AddSheet?
    @State private var editingItem: TimelineEditItem?
    @State private var openTimelineID: String?
    @State private var customProteinInput = ""
    @State private var customWaterInput = ""
    @State private var pendingFoodAction: DayFoodAction?
    @State private var showProteinPicker = false
    @State private var activeScanSheet: DayScanSheetState?
    @State private var isLookingUpBarcode = false
    @FocusState private var isCustomProteinFocused: Bool
    @FocusState private var isCustomWaterFocused: Bool

    private let openFoodFactsService = OpenFoodFactsService()
    private let proteinQuickAmounts = [10, 20, 30, 40]
    private let waterQuickAmounts = [150, 250, 500, 1000]

    private enum DayFoodAction {
        case pickFood
        case scan
    }

    private enum AddSheet: Identifiable {
        case food(dateIso: String)
        case water(dateIso: String)
        case bloodSugar(dateIso: String)
        case symptom(dateIso: String)

        var id: String {
            switch self {
            case .food(let dateIso): return "food-\(dateIso)"
            case .water(let dateIso): return "water-\(dateIso)"
            case .bloodSugar(let dateIso): return "bs-\(dateIso)"
            case .symptom(let dateIso): return "sym-\(dateIso)"
            }
        }
    }

    private struct DayScanSheetState: Identifiable {
        enum Kind {
            case scanner
            case loading
            case result(FoodProduct)
            case error(message: String, allowsManualEntry: Bool)
        }

        let id = UUID()
        let kind: Kind
    }

    private var recordsByDate: [String: DayRecord] {
        Dictionary(uniqueKeysWithValues: weekRecords.map { ($0.date, $0) })
    }

    private var lastSevenDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - 6, to: today) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                dayNavigator
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)

                weekStrip
                    .padding(.horizontal, Theme.Spacing.lg)

                if !isLoading {
                    daySummaryCard
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                timelineContent
            }

            floatingAddButton
        }
        .navigationTitle("Dag")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: dateIso) {
            await loadEvents()
            await loadWeekRecords()
        }
        .onAppear {
            Task { await reloadAll() }
        }
        .onChange(of: healthManager.steps) { _, steps in
            if isToday, healthManager.isAuthorized {
                daySteps = steps
            }
        }
        .sheet(isPresented: $showAddOptions, onDismiss: {
            if let pending = pendingAdd {
                pendingAdd = nil
                activeSheet = pending
            }
        }) {
            AddOptionsSheet { option in
                switch option {
                case .water: pendingAdd = .water(dateIso: dateIso)
                case .protein: pendingAdd = .food(dateIso: dateIso)
                case .bloodSugar: pendingAdd = .bloodSugar(dateIso: dateIso)
                case .symptom: pendingAdd = .symptom(dateIso: dateIso)
                }
                showAddOptions = false
            }
            .adaptiveBottomSheet()
        }
        .sheet(item: $activeSheet, onDismiss: {
            Task { await reloadAll() }
            switch pendingFoodAction {
            case .pickFood: showProteinPicker = true
            case .scan: startScanFlow()
            case .none: break
            }
            pendingFoodAction = nil
        }) { sheet in
            switch sheet {
            case .food(let iso):
                HomeFoodSheet(
                    amounts: proteinQuickAmounts,
                    text: $customProteinInput,
                    fieldFocus: $isCustomProteinFocused,
                    onQuickAdd: { addQuickProtein($0, on: iso) },
                    onCustomAdd: { addCustomProtein(on: iso) },
                    onPickFood: { pendingFoodAction = .pickFood; activeSheet = nil },
                    onScan: { pendingFoodAction = .scan; activeSheet = nil }
                )
                .adaptiveBottomSheet()
            case .water(let iso):
                HomeWaterSheet(
                    amounts: waterQuickAmounts,
                    text: $customWaterInput,
                    fieldFocus: $isCustomWaterFocused,
                    onQuickAdd: { addQuickWater($0, on: iso) },
                    onCustomAdd: { addCustomWater(on: iso) }
                )
                .adaptiveBottomSheet()
            case .bloodSugar(let iso):
                NavigationStack {
                    BloodSugarLogView(dateIso: iso).environmentObject(healthViewModel)
                }
                .adaptiveBottomSheet(
                    extraHeight: AdaptiveBottomSheetMetrics.navigationBarHeight,
                    wrapsContent: false
                )
            case .symptom(let iso):
                NavigationStack {
                    SymptomLogView(dateIso: iso).environmentObject(healthViewModel)
                }
                .adaptiveBottomSheet(
                    extraHeight: AdaptiveBottomSheetMetrics.navigationBarHeight,
                    wrapsContent: false
                )
            }
        }
        .sheet(isPresented: $showProteinPicker, onDismiss: { Task { await reloadAll() } }) {
            ProteinSourcePickerView(dateIso: dateIso, viewModel: proteinViewModel)
        }
        .sheet(item: $activeScanSheet) { sheet in
            switch sheet.kind {
            case .scanner:
                BarcodeScannerView(
                    onScan: { code in handleScannedBarcode(code) },
                    onCancel: { activeScanSheet = nil },
                    onFailure: { message in
                        activeScanSheet = DayScanSheetState(
                            kind: .error(message: message, allowsManualEntry: true)
                        )
                    }
                )
            case .loading:
                ScanLoadingView(onCancel: { activeScanSheet = nil })
            case let .result(product):
                ScanResultView(
                    product: product,
                    onConfirm: { quantity in applyScannedProduct(product, quantity: quantity) },
                    onCancel: { activeScanSheet = nil }
                )
            case let .error(message, allowsManualEntry):
                ScanErrorView(
                    message: message,
                    allowsManualEntry: allowsManualEntry,
                    onRetry: { startScanFlow() },
                    onManualEntry: {
                        activeScanSheet = nil
                        activeSheet = .food(dateIso: dateIso)
                    },
                    onCancel: { activeScanSheet = nil }
                )
            }
        }
        .sheet(item: $editingItem, onDismiss: { Task { await reloadAll() } }) { item in
            TimelineEditSheet(item: item, dateIso: dateIso) {
                Task { await reloadAll() }
            }
            .environmentObject(proteinViewModel)
            .environmentObject(healthViewModel)
            .adaptiveBottomSheet(
                extraHeight: AdaptiveBottomSheetMetrics.navigationBarHeight,
                wrapsContent: false
            )
        }
    }

    
    // MARK: - Day navigator
 
    private var dayNavigator: some View {
        HStack {
            navButton(systemName: "chevron.left") { shiftDay(by: -1) }
            Spacer()
            VStack(spacing: 2) {
                Text(relativeDateLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                Text(fullDateLabel)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            Spacer()
            navButton(systemName: "chevron.right") { shiftDay(by: 1) }
                .opacity(isToday ? 0.3 : 1)
                .disabled(isToday)
        }
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .frame(width: 42, height: 42)
                .background(Theme.Colors.surface2)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(lastSevenDays, id: \.self) { date in
                let key = DayFormatting.isoString(from: date)
                let record = recordsByDate[key]
                let consumed = record?.proteinConsumed ?? 0
                let goal = record?.proteinGoal ?? proteinViewModel.proteinGoal
                let percentage = goal > 0 ? min((consumed / goal) * 100, 100) : 0
                let isSelected = key == dateIso

                Button {
                    selectedDate = date
                } label: {
                    DayWeekStripColumn(
                        date: date,
                        percentage: percentage,
                        isSelected: isSelected
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var daySummaryCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                summaryRow(
                    label: "Eiwit",
                    value: "\(grams(proteinConsumed))g",
                    subtitle: proteinGoal > 0 ? "doel \(grams(proteinGoal))g" : nil
                )

                StyledProgressBar(percentage: proteinPercentage)

                Divider()
                    .background(Color.white.opacity(0.08))

                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    summaryStatBlock(
                        label: "Water",
                        value: "\(Int(waterConsumedMl)) ml",
                        icon: "drop.fill",
                        iconColor: Theme.Colors.blue
                    )
                    summaryStatBlock(
                        label: "Stappen",
                        value: stepsSummaryText,
                        icon: "figure.walk",
                        iconColor: Theme.Colors.green
                    )
                }

                if healthManager.isAuthorized, let steps = daySteps {
                    StepDotBar(steps: steps, goal: stepsGoal)
                }

                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    summaryStatBlock(
                        label: "Gevoel",
                        value: averageFeelingText,
                        icon: "face.smiling",
                        iconColor: Theme.Colors.accent
                    )
                    summaryStatBlock(
                        label: "Bloedsuiker",
                        value: averageBloodSugarText,
                        icon: "drop.circle.fill",
                        iconColor: Theme.Colors.green
                    )
                }
            }
        }
    }

    private func summaryRow(label: String, value: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textMuted)
                .tracking(0.4)
                .textCase(.uppercase)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.text)
                    .monospacedDigit()
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
        }
    }

    private func summaryStatBlock(
        label: String,
        value: String,
        icon: String,
        iconColor: Color,
        fullWidth: Bool = false
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.3)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            if !fullWidth { Spacer(minLength: 0) }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
    }

    // MARK: - Timeline

    @ViewBuilder
    private var timelineContent: some View {
        if isLoading {
            ProgressView()
                .tint(Theme.Colors.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text("Tijdlijn")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.sm)

                    ForEach(events) { event in
                        SwipeableActionRow(
                            id: event.id,
                            openID: $openTimelineID,
                            onEdit: { editingItem = TimelineEditItem(event: event) },
                            onDelete: { Task { await delete(event) } }
                        ) {
                            TimelineRow(event: event)
                                .padding(.horizontal, Theme.Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.Colors.surface)
                        }

                        if event.id != events.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, Theme.Spacing.lg)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
        }
    }

    private var floatingAddButton: some View {
        Button { showAddOptions = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.Colors.background)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.green)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(Theme.Spacing.xl)
    }

    // MARK: - Summary computed values

    private var effectiveWeight: Double {
        let fromAccount = Double(accountViewModel.weight) ?? 0
        if fromAccount > 0 { return fromAccount }
        return dayRecord?.weight ?? 0
    }

    private var proteinConsumed: Double {
        if let entries = dayRecord?.entries, !entries.isEmpty {
            return entries.reduce(0) { $0 + $1.proteinAmount }
        }
        if isToday { return proteinViewModel.proteinConsumed }
        return dayRecord?.proteinConsumed ?? 0
    }

    private var proteinGoal: Double {
        let fromRecord = dayRecord?.proteinGoal ?? 0
        if fromRecord > 0 { return fromRecord }
        let computed = effectiveWeight * (dayRecord?.activityFactor ?? accountViewModel.activityFactor)
        if computed > 0 { return computed }
        return proteinViewModel.proteinGoal
    }

    private var proteinPercentage: Double {
        guard proteinGoal > 0 else { return 0 }
        return min((proteinConsumed / proteinGoal) * 100, 100)
    }

    private var bloodSugarReadings: [BloodSugarEntry] {
        events.compactMap { event in
            guard case .bloodSugar(let entry) = event else { return nil }
            return entry
        }
    }

    private var symptomEntriesForDay: [SymptomEntry] {
        events.compactMap { event in
            guard case .symptom(let entry) = event else { return nil }
            return entry
        }
    }

    private var averageBloodSugar: Double? {
        let values = bloodSugarReadings.map(\.valueMmol)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var averageFeelingLevel: Double? {
        let levels = symptomEntriesForDay.flatMap { entry -> [Int] in
            [entry.energyLevel, entry.focusLevel, entry.hungerLevel].compactMap { $0 }
        }
        guard !levels.isEmpty else { return nil }
        return Double(levels.reduce(0, +)) / Double(levels.count)
    }

    private var averageBloodSugarText: String {
        guard let avg = averageBloodSugar else { return "Geen metingen" }
        return String(format: "%.1f mmol/L gem.", avg)
    }

    private var averageFeelingText: String {
        guard let avg = averageFeelingLevel else { return "Geen logs" }
        let emoji = SymptomDimension.energy.emoji(for: Int(avg.rounded()))
        return "\(emoji) \(String(format: "%.1f", avg))/5 gem."
    }

    private let stepsGoal = 10_000

    private var stepsSummaryText: String {
        guard healthManager.isAuthorized else { return "Niet gekoppeld" }
        guard let steps = daySteps else { return "—" }
        let formatted = formattedSteps(steps)
        if isToday { return "\(formatted) tot nu" }
        return formatted
    }

    private func formattedSteps(_ steps: Int) -> String {
        guard steps >= 1000 else { return String(steps) }
        return String(format: "%d.%03d", steps / 1000, steps % 1000)
    }

    // MARK: - Date helpers

    private var dateIso: String {
        DayFormatting.isoString(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var relativeDateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) { return "Vandaag" }
        if calendar.isDateInYesterday(selectedDate) { return "Gisteren" }
        return shortDateFormatter.string(from: selectedDate).capitalized
    }

    private var fullDateLabel: String {
        fullDateFormatter.string(from: selectedDate).capitalized
    }

    private func shiftDay(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) else { return }
        if days > 0 && newDate > Date() { return }
        selectedDate = newDate
    }

    private func grams(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    // MARK: - Food & water add

    private func closeInputSheet() {
        activeSheet = nil
        customProteinInput = ""
        customWaterInput = ""
        isCustomProteinFocused = false
        isCustomWaterFocused = false
    }

    private func addQuickProtein(_ grams: Int, on dateIso: String) {
        Task {
            await proteinViewModel.addManualProtein(grams: Double(grams), to: dateIso)
            await reloadAll()
            await MainActor.run { closeInputSheet() }
        }
    }

    private func addCustomProtein(on dateIso: String) {
        let normalized = customProteinInput.replacingOccurrences(of: ",", with: ".")
        let amount = Double(normalized) ?? 0
        guard amount > 0 else { return }
        Task {
            await proteinViewModel.addManualProtein(grams: amount, to: dateIso)
            await reloadAll()
            await MainActor.run { closeInputSheet() }
        }
    }

    private func addQuickWater(_ milliliters: Int, on dateIso: String) {
        Task {
            try? await proteinViewModel.addWaterEntry(milliliters: milliliters, to: dateIso)
            await reloadAll()
            await MainActor.run { closeInputSheet() }
        }
    }

    private func addCustomWater(on dateIso: String) {
        let amount = Int(customWaterInput) ?? 0
        guard amount > 0 else { return }
        Task {
            try? await proteinViewModel.addWaterEntry(milliliters: amount, to: dateIso)
            await reloadAll()
            await MainActor.run { closeInputSheet() }
        }
    }

    private func startScanFlow() {
        activeScanSheet = DayScanSheetState(kind: .scanner)
    }

    private func handleScannedBarcode(_ barcode: String) {
        guard isLookingUpBarcode == false else { return }
        isLookingUpBarcode = true
        activeScanSheet = DayScanSheetState(kind: .loading)

        Task {
            defer { isLookingUpBarcode = false }
            do {
                let product = try await openFoodFactsService.fetchProduct(barcode: barcode)
                await MainActor.run {
                    activeScanSheet = DayScanSheetState(kind: .result(product))
                }
            } catch let error as OpenFoodFactsError {
                await MainActor.run {
                    let allowManual = (error == .productNotFound || error == .missingProteinData)
                    activeScanSheet = DayScanSheetState(
                        kind: .error(
                            message: error.localizedDescription,
                            allowsManualEntry: allowManual
                        )
                    )
                }
            } catch {
                await MainActor.run {
                    activeScanSheet = DayScanSheetState(
                        kind: .error(
                            message: "Er ging iets mis met scannen. Probeer opnieuw of voer het handmatig in.",
                            allowsManualEntry: true
                        )
                    )
                }
            }
        }
    }

    private func applyScannedProduct(_ product: FoodProduct, quantity: Double) {
        Task {
            await proteinViewModel.addScannedProduct(product, quantity: quantity, to: dateIso)
            await reloadAll()
            await MainActor.run { activeScanSheet = nil }
        }
    }

    // MARK: - Delete

    private func delete(_ event: TimelineEvent) async {
        switch event {
        case .meal(let entry):
            await proteinViewModel.removeProteinEntry(entry, from: dateIso)
        case .water(let entry):
            try? await proteinViewModel.removeWaterEntry(entry, from: dateIso)
        case .bloodSugar(let entry):
            await healthViewModel.deleteBloodSugar(entry)
        case .symptom(let entry):
            await healthViewModel.deleteSymptom(entry)
        }
        await reloadAll()
    }

    // MARK: - Loading

    private func reloadAll() async {
        await loadEvents()
        await loadWeekRecords()
        if dateIso == proteinViewModel.today {
            await proteinViewModel.refresh()
            await healthViewModel.loadToday()
        }
    }

    private func loadWeekRecords() async {
        weekRecords = await proteinViewModel.allRecords()
    }

    private func loadEvents() async {
        isLoading = true
        let iso = dateIso

        async let record = proteinViewModel.record(for: iso)
        async let water = proteinViewModel.waterEntries(for: iso)
        async let readings = healthViewModel.readings(for: iso)
        async let symptoms = healthViewModel.symptoms(for: iso)
        async let steps = healthManager.fetchStepCount(for: selectedDate)

        let fetchedRecord = await record
        let waterEntries = await water
        let bsEntries = await readings
        let symptomEntries = await symptoms
        let fetchedSteps = await steps

        dayRecord = fetchedRecord
        waterConsumedMl = Double(waterEntries.reduce(0) { $0 + $1.milliliters })
        daySteps = fetchedSteps

        if let record = fetchedRecord {
            let weight = effectiveWeight
            if weight > 0 {
                let newGoal = weight * record.activityFactor
                if abs(record.weight - weight) > 0.01 || abs(record.proteinGoal - newGoal) > 0.01 {
                    var updated = record
                    updated.weight = weight
                    updated.proteinGoal = newGoal
                    dayRecord = updated
                    proteinViewModel.saveDayRecord(updated)
                }
            }
        }

        var combined: [TimelineEvent] = []
        combined += (fetchedRecord?.entries ?? []).map { TimelineEvent.meal($0) }
        combined += waterEntries.map { TimelineEvent.water($0) }
        combined += bsEntries.map { TimelineEvent.bloodSugar($0) }
        combined += symptomEntries.map { TimelineEvent.symptom($0) }
        combined.sort { $0.timestamp < $1.timestamp }

        events = combined
        isLoading = false
    }

    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()

    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter
    }()
}

// MARK: - Week strip column

private struct DayWeekStripColumn: View {
    let date: Date
    let percentage: Double
    let isSelected: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(DayFormatting.weekStripLabel(for: date))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.Colors.green : Theme.Colors.textMuted)

            VerticalProgressBar(
                percentage: percentage,
                width: 14,
                height: 52,
                cornerRadius: 6,
                style: .statusTint,
                showGlow: false,
                outlineLineWidth: 1,
                outlineOpacity: isSelected ? 0.35 : 0.16
            )

            Text("\(Int(round(percentage)))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.Colors.green : Theme.Colors.text)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(isSelected ? Theme.Colors.green.opacity(0.1) : Color.clear)
        )
    }
}

private struct TimelineRow: View {
    let event: TimelineEvent

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(Self.timeFormatter.string(from: event.timestamp))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
                .frame(width: 44, alignment: .leading)
                .monospacedDigit()

            ZStack {
                Circle()
                    .fill(event.color.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: event.icon)
                    .font(.system(size: 14))
                    .foregroundColor(event.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                if !event.subtitle.isEmpty {
                    Text(event.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()
}
