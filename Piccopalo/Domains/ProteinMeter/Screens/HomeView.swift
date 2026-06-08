import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var healthViewModel: HealthViewModel
    @ObservedObject private var notificationStore = NotificationStore.shared
    @State private var showProteinPicker = false
    @State private var activeScanSheet: ScanSheetState?
    @State private var isLookingUpBarcode = false
    @State private var showFoodOptions = false
    @State private var showWaterOptions = false
    @State private var pendingFoodAction: FoodAction?
    @State private var customProteinInput: String = ""
    @State private var customWaterInput: String = ""
    @State private var showBloodSugarLog = false
    @State private var showSymptomLog = false
    @FocusState private var isCustomProteinFocused: Bool
    @FocusState private var isCustomWaterFocused: Bool

    private let openFoodFactsService = OpenFoodFactsService()
    private let proteinQuickAmounts = [10, 20, 30, 40]
    private let waterQuickAmounts = [150, 250, 500, 1000]

    private enum FoodAction {
        case pickFood
        case scan
    }

    private struct ScanSheetState: Identifiable {
        enum Kind {
            case scanner
            case loading
            case result(FoodProduct)
            case error(message: String, allowsManualEntry: Bool)
        }

        let id = UUID()
        let kind: Kind
    }

    private func startScanFlow() {
        activeScanSheet = ScanSheetState(kind: .scanner)
    }

    private func handleScannedBarcode(_ barcode: String) {
        guard isLookingUpBarcode == false else { return }
        isLookingUpBarcode = true
        activeScanSheet = ScanSheetState(kind: .loading)

        Task {
            defer { isLookingUpBarcode = false }
            do {
                let product = try await openFoodFactsService.fetchProduct(barcode: barcode)
                await MainActor.run {
                    activeScanSheet = ScanSheetState(kind: .result(product))
                }
            } catch let error as OpenFoodFactsError {
                await MainActor.run {
                    let allowManual = (error == .productNotFound || error == .missingProteinData)
                    activeScanSheet = ScanSheetState(
                        kind: .error(
                            message: error.localizedDescription,
                            allowsManualEntry: allowManual
                        )
                    )
                }
            } catch {
                await MainActor.run {
                    activeScanSheet = ScanSheetState(
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
        viewModel.addScannedProduct(product, quantity: quantity)
        activeScanSheet = nil
    }

    private func addWater(_ milliliters: Int) {
        Task {
            do {
                try await viewModel.addWaterEntry(milliliters: milliliters)
                // Trigger notification scheduler to check if goal was reached
                let scheduler = WaterNotificationScheduler()
                await scheduler.scheduleDaily(currentWaterMl: Int(viewModel.waterConsumed), goalMl: viewModel.waterGoal)
            } catch {
                print("Error adding water entry: \(error)")
            }
        }
    }

    private func addCustomWater() {
        let amount = Int(customWaterInput) ?? 0
        guard amount > 0 else { return }
        addWater(amount)
        customWaterInput = ""
        isCustomWaterFocused = false
        showWaterOptions = false
    }

    private func addQuickWater(_ milliliters: Int) {
        addWater(milliliters)
        showWaterOptions = false
        customWaterInput = ""
        isCustomWaterFocused = false
    }

    private func addCustomProtein() {
        let normalized = customProteinInput.replacingOccurrences(of: ",", with: ".")
        let amount = Double(normalized) ?? 0
        guard amount > 0 else { return }
        viewModel.proteinInput = normalized
        viewModel.addProtein()
        customProteinInput = ""
        isCustomProteinFocused = false
        showFoodOptions = false
    }

    private func addQuickProtein(_ grams: Int) {
        viewModel.proteinInput = String(grams)
        viewModel.addProtein()
        showFoodOptions = false
        customProteinInput = ""
        isCustomProteinFocused = false
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "ochtend" }
        if hour < 17 { return "middag" }
        return "avond"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEEE, d MMM"
        return f.string(from: Date()).capitalized
    }

    private var statusText: String {
        let pct = viewModel.percentage
        if pct >= 100 { return "doel gehaald" }
        if pct >= 75 { return "bijna daar" }
        if pct >= 40 { return "op schema" }
        return "begin vandaag"
    }

    private var userName: String {
        accountViewModel.name.isEmpty ? "jou" : accountViewModel.name
    }

    private var userInitial: String {
        String(userName.prefix(1)).uppercased()
    }

    private func formattedSteps(_ steps: Int) -> String {
        guard steps >= 1000 else { return String(steps) }
        return String(format: "%d.%03d", steps / 1000, steps % 1000)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(formattedDate)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.textMuted)

                        Text("Goede ")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(Theme.Colors.text)
                            +
                            Text(greeting + ", ")
                            .font(.system(size: 20).italic())
                            .foregroundColor(Theme.Colors.text)
                        +
                            Text(userName)
                            .font(.custom(Theme.Typography.displayFont, size: 20).italic())
                            .foregroundColor(Theme.Colors.text)
                    }
                    Spacer()
                    NavigationLink(destination: AccountView().environmentObject(accountViewModel)) {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.surface2)
                                    .frame(width: 42, height: 42)
                                Text(userInitial)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text)
                            }

                            if notificationStore.unreadCount > 0 {
                                Circle()
                                    .fill(Theme.Colors.tomato)
                                    .frame(width: 9, height: 9)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
                .padding(.top, Theme.Spacing.sm)

                StyledCard {
                    VStack(spacing: Theme.Spacing.lg) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("EIWIT · VANDAAG")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textMuted)
                                    .tracking(0.7)
                                Text("Mijn protein")
                                    .font(.custom(Theme.Typography.displayFont, size: 20).italic())
                                    .foregroundColor(Theme.Colors.text)
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", viewModel.percentage) + " · " + statusText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.Colors.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.Colors.green.opacity(0.14))
                                .clipShape(Capsule())
                        }

                        DualRingProgressView(
                            proteinPercentage: viewModel.percentage / 100,
                            waterPercentage: viewModel.waterPercentage,
                            proteinConsumed: viewModel.proteinConsumed,
                            proteinGoal: viewModel.proteinGoal,
                            waterMl: Int(viewModel.waterConsumed),
                            waterGoal: viewModel.waterGoal
                        )
                        .frame(height: 210)

                        HStack(spacing: Theme.Spacing.sm) {
                            AppButton(
                                title: "Voedsel",
                                icon: "fork.knife",
                                size: .fullWidth,
                                background: Theme.Colors.green.opacity(0.14),
                                foreground: Theme.Colors.green,
                                cornerStyle: .rounded(Theme.Radius.md),
                                action: { showFoodOptions = true }
                            )

                            AppButton(
                                title: "Water",
                                icon: "waterbottle.fill",
                                size: .fullWidth,
                                background: Theme.Colors.blue.opacity(0.14),
                                foreground: Theme.Colors.blue,
                                cornerStyle: .rounded(Theme.Radius.md),
                                action: { showWaterOptions = true }
                            )
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            AppButton(
                                title: "Bloedsuiker",
                                icon: "drop.fill",
                                size: .fullWidth,
                                background: Theme.Colors.tomato.opacity(0.14),
                                foreground: Theme.Colors.tomato,
                                cornerStyle: .rounded(Theme.Radius.md),
                                action: { showBloodSugarLog = true }
                            )

                            AppButton(
                                title: "Gevoel",
                                icon: "face.smiling",
                                size: .fullWidth,
                                background: Theme.Colors.cream.opacity(0.14),
                                foreground: Theme.Colors.cream,
                                cornerStyle: .rounded(Theme.Radius.md),
                                action: { showSymptomLog = true }
                            )
                        }
                    }
                }

                StyledCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.Colors.surface2)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.Colors.textMuted)
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text("BEWEGING")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textMuted)
                                    .tracking(0.7)
                                Text("Mijn stappen")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            Spacer()
                            Text(healthManager.isAuthorized ? "✓ Gekoppeld" : "Niet gekoppeld")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(healthManager.isAuthorized
                                    ? Theme.Colors.green
                                    : Theme.Colors.tomato)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(formattedSteps(healthManager.steps))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Theme.Colors.green)
                                .monospacedDigit()
                            Text("van 10.000")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textMuted)
                            Spacer()
                            Text(String(format: "%.0f%%", min((Double(healthManager.steps) / 10000) * 100, 100)))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Theme.Colors.text)
                                .monospacedDigit()
                        }

                        StepDotBar(steps: Int(healthManager.steps), goal: 10000)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background)
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            Task { await healthManager.fetchTodayData() }
        }
        .sheet(isPresented: $showFoodOptions, onDismiss: {
            switch pendingFoodAction {
            case .pickFood: showProteinPicker = true
            case .scan: startScanFlow()
            case .none: break
            }
            pendingFoodAction = nil
        }) {
            HomeFoodSheet(
                amounts: proteinQuickAmounts,
                text: $customProteinInput,
                fieldFocus: $isCustomProteinFocused,
                onQuickAdd: addQuickProtein,
                onCustomAdd: addCustomProtein,
                onPickFood: { pendingFoodAction = .pickFood; showFoodOptions = false },
                onScan: { pendingFoodAction = .scan; showFoodOptions = false }
            )
            .adaptiveBottomSheet()
        }
        .sheet(isPresented: $showWaterOptions) {
            HomeWaterSheet(
                amounts: waterQuickAmounts,
                text: $customWaterInput,
                fieldFocus: $isCustomWaterFocused,
                onQuickAdd: addQuickWater,
                onCustomAdd: addCustomWater
            )
            .adaptiveBottomSheet()
        }
        .sheet(isPresented: $showProteinPicker) {
            ProteinSourcePickerView(viewModel: viewModel)
        }
        .sheet(item: $activeScanSheet) { sheet in
            switch sheet.kind {
            case .scanner:
                BarcodeScannerView(
                    onScan: { code in handleScannedBarcode(code) },
                    onCancel: { activeScanSheet = nil },
                    onFailure: { message in
                        activeScanSheet = ScanSheetState(
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
                        showFoodOptions = true
                    },
                    onCancel: { activeScanSheet = nil }
                )
            }
        }
        .sheet(isPresented: $showBloodSugarLog) {
            NavigationStack {
                BloodSugarLogView().environmentObject(healthViewModel)
            }
            .adaptiveBottomSheet(
                extraHeight: AdaptiveBottomSheetMetrics.navigationBarHeight,
                wrapsContent: false
            )
        }
        .sheet(isPresented: $showSymptomLog) {
            NavigationStack {
                SymptomLogView().environmentObject(healthViewModel)
            }
            .adaptiveBottomSheet(
                extraHeight: AdaptiveBottomSheetMetrics.navigationBarHeight,
                wrapsContent: false
            )
        }
    }
}

private struct HomeStatColumn: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProteinViewModel(
            diaryRepository: SupabaseDiaryRepository(),
            userProfileRepository: SupabaseUserProfileRepository(),
            waterRepository: SupabaseWaterRepository()
        ))
        .environmentObject(AccountViewModel(
            userProfileRepository: SupabaseUserProfileRepository()
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(HealthManager())
        .environmentObject(HealthViewModel(
            bloodSugarRepository: SupabaseBloodSugarRepository(),
            symptomRepository: SupabaseSymptomRepository()
        ))
}
