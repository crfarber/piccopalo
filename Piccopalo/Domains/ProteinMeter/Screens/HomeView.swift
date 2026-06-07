import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var healthManager: HealthManager
    @ObservedObject private var notificationStore = NotificationStore.shared
    @State private var showProteinPicker = false
    @State private var activeScanSheet: ScanSheetState?
    @State private var isLookingUpBarcode = false
    @State private var showCustomProteinInput = false
    @State private var customProteinInput: String = ""
    @State private var showCustomWaterInput = false
    @State private var customWaterInput: String = ""
    @FocusState private var isCustomProteinFocused: Bool
    @FocusState private var isCustomWaterFocused: Bool

    private let openFoodFactsService = OpenFoodFactsService()

    private enum ManualInputSheetKind {
        case protein
        case water
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
        let source = ProteinSource(name: product.name, proteinPer100g: product.proteinPer100g, unit: .grams)
        viewModel.addProtein(source: source, quantity: quantity)
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
        showCustomWaterInput = false
    }

    private func addCustomProtein() {
        let normalized = customProteinInput.replacingOccurrences(of: ",", with: ".")
        let amount = Double(normalized) ?? 0
        guard amount > 0 else { return }
        viewModel.proteinInput = normalized
        viewModel.addProtein()
        customProteinInput = ""
        isCustomProteinFocused = false
        showCustomProteinInput = false
    }

    private func manualInputSheetHeight(for kind: ManualInputSheetKind) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let isVerySmallScreen = screenHeight <= 700
        let isCompactScreen = screenHeight <= 820

        switch kind {
        case .protein:
            if isVerySmallScreen { return 310 }
            if isCompactScreen { return 285 }
            return 255
        case .water:
            if isVerySmallScreen { return 300 }
            if isCompactScreen { return 275 }
            return 245
        }
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
                            .font(.system(size: 26, weight: .bold, design: .default))
                            .foregroundColor(Theme.Colors.text)
                            +
                            Text(greeting + ", ")
                            .font(.system(size: 26).italic())
                            .foregroundColor(Theme.Colors.text)

                        Text(userName)
                            .font(.custom(Theme.Typography.displayFont, size: 26).italic())
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

                        HStack(spacing: 0) {
                            HomeStatColumn(
                                value: String(format: "%.0fg", viewModel.proteinConsumed),
                                label: "GEGETEN",
                                color: Theme.Colors.green
                            )
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 36)
                            HomeStatColumn(
                                value: String(format: "%.0fg", viewModel.proteinGoal),
                                label: "DOEL",
                                color: Theme.Colors.text
                            )
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 36)
                            HomeStatColumn(
                                value: String(format: "%.0fg", viewModel.remaining),
                                label: "TE GAAN",
                                color: Theme.Colors.tomato
                            )
                        }
                        Divider()

                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Protein (gram)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach([10, 20, 30, 40, 50], id: \.self) { amount in
                                AppButton(
                                    title: "\(amount)",
                                    icon: nil,
                                    size: .small,
                                    background: Theme.Colors.green.opacity(0.12),
                                    foreground: Theme.Colors.green,
                                    cornerStyle: .pill,
                                    action: {
                                        viewModel.proteinInput = String(amount)
                                        viewModel.addProtein()
                                    }
                                )
                            }
                            AppButton(
                                title: "+",
                                icon: nil,
                                size: .small,
                                background: Theme.Colors.green.opacity(0.12),
                                foreground: Theme.Colors.green,
                                cornerStyle: .pill,
                                action: { showCustomProteinInput = true }
                            )
                            Spacer()
                        }


                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Water (ml)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        // Water quick buttons
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach([150, 250, 500, 1000], id: \.self) { ml in
                                AppButton(
                                    title: "\(ml)",
                                    icon: nil,
                                    size: .small,
                                    background: Theme.Colors.blue.opacity(0.12),
                                    foreground: Theme.Colors.blue,
                                    cornerStyle: .pill,
                                    action: { addWater(ml) }
                                )
                            }
                            AppButton(
                                title: "+",
                                icon: nil,
                                size: .small,
                                background: Theme.Colors.blue.opacity(0.12),
                                foreground: Theme.Colors.blue,
                                cornerStyle: .pill,
                                action: { showCustomWaterInput = true }
                            )
                            Spacer()
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            AppButton(
                                title: "Kies voedsel",
                                icon: "list.bullet",
                                size: .fullWidth,
                                background: Theme.Colors.surface2,
                                foreground: Theme.Colors.text,
                                cornerStyle: .rounded(Theme.Radius.md),
                                action: { showProteinPicker = true }
                            )

                            AppButton(
                                title: "Scan",
                                icon: "barcode.viewfinder",
                                size: .fullWidth,
                                background: Theme.Colors.surface2,
                                foreground: Theme.Colors.text,
                                cornerStyle: .rounded(Theme.Radius.md),
                                action: { startScanFlow() }
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
                        showCustomProteinInput = true
                    },
                    onCancel: { activeScanSheet = nil }
                )
            }
        }
        .sheet(isPresented: $showCustomProteinInput) {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Voeg eiwit toe")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Theme.Spacing.sm) {
                    TextInput(
                        label: "",
                        text: $customProteinInput,
                        placeholder: "0",
                        unit: "gram",
                        keyboard: .decimal,
                        textInputAutocapitalization: .never,
                        disableAutocorrection: true,
                        fieldFocus: $isCustomProteinFocused
                    )
                    .onChange(of: customProteinInput) {
                        let filtered = customProteinInput.filter { "0123456789.,".contains($0) }
                        if filtered.filter({ $0 == "." || $0 == "," }).count > 1 {
                            let normalized = filtered.replacingOccurrences(of: ",", with: ".")
                            customProteinInput = String(normalized.prefix(while: { $0 != "." }))
                                + "."
                                + normalized.drop(while: { $0 != "." }).dropFirst().filter { $0 != "." }
                        } else {
                            customProteinInput = filtered
                        }
                    }

                    AppButton(
                        title: nil,
                        icon: "plus",
                        size: .square(58),
                        background: Theme.Colors.green,
                        foreground: Theme.Colors.background,
                        cornerStyle: .rounded(Theme.Radius.md),
                        action: { addCustomProtein() }
                    )
                }

                HStack(spacing: Theme.Spacing.sm) {
                    AppButton(
                        title: "Annuleer",
                        icon: nil,
                        size: .fullWidth,
                        background: Theme.Colors.surface2,
                        foreground: Theme.Colors.text,
                        cornerStyle: .rounded(Theme.Radius.md),
                        action: {
                            showCustomProteinInput = false
                            customProteinInput = ""
                            isCustomProteinFocused = false
                        }
                    )
                }
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.background)
            .presentationDetents([.height(manualInputSheetHeight(for: .protein))])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.Colors.background)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isCustomProteinFocused = true
                }
            }
        }
        .sheet(isPresented: $showCustomWaterInput) {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Voeg water toe")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Theme.Spacing.sm) {
                    TextInput(
                        label: "",
                        text: $customWaterInput,
                        placeholder: "0",
                        unit: "ml",
                        keyboard: .integer,
                        textInputAutocapitalization: .never,
                        disableAutocorrection: true,
                        fieldFocus: $isCustomWaterFocused
                    )
                    .onChange(of: customWaterInput) {
                        customWaterInput = customWaterInput.filter { "0123456789".contains($0) }
                    }

                    AppButton(
                        title: nil,
                        icon: "plus",
                        size: .square(58),
                        background: Theme.Colors.blue,
                        foreground: Theme.Colors.background,
                        cornerStyle: .rounded(Theme.Radius.md),
                        action: { addCustomWater() }
                    )
                }

                HStack(spacing: Theme.Spacing.sm) {
                    AppButton(
                        title: "Annuleer",
                        icon: nil,
                        size: .fullWidth,
                        background: Theme.Colors.surface2,
                        foreground: Theme.Colors.text,
                        cornerStyle: .rounded(Theme.Radius.md),
                        action: {
                            showCustomWaterInput = false
                            customWaterInput = ""
                            isCustomWaterFocused = false
                        }
                    )
                }
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.background)
            .presentationDetents([.height(manualInputSheetHeight(for: .water))])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.Colors.background)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isCustomWaterFocused = true
                }
            }
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
}
