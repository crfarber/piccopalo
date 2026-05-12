import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var healthManager: HealthManager
    @FocusState private var proteinInputFocused: Bool
    @State private var showProteinPicker = false
    @State private var activeScanSheet: ScanSheetState?
    @State private var isLookingUpBarcode = false

    private let openFoodFactsService = OpenFoodFactsService()

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

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Goeie ochtend" }
        if hour < 17 { return "Goeie middag" }
        return "Goeie avond"
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
        if pct >= 75  { return "bijna daar" }
        if pct >= 40  { return "op schema" }
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
            VStack(spacing: DesignTokens.Spacing.lg) {

                // ── Header ────────────────────────────────────────────
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(formattedDate)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textMuted)

                        (
                            Text(greeting + ", ")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(DesignTokens.Colors.text)
                            + Text(userName)
                                .font(.custom(DesignTokens.Typography.displayFont, size: 26).italic())
                                .foregroundColor(DesignTokens.Colors.text)
                        )
                    }
                    Spacer()
                    NavigationLink(destination: AccountView().environmentObject(accountViewModel)) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.surface2)
                                .frame(width: 42, height: 42)
                            Text(userInitial)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.text)
                        }
                    }
                }
                .padding(.top, DesignTokens.Spacing.sm)

                // ── Protein ring card ─────────────────────────────────
                StyledCard {
                    VStack(spacing: DesignTokens.Spacing.lg) {

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("EIWIT · VANDAAG")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.textMuted)
                                    .tracking(0.7)
                                Text("Mijn protein")
                                    .font(.custom(DesignTokens.Typography.displayFont, size: 20).italic())
                                    .foregroundColor(DesignTokens.Colors.text)
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", viewModel.percentage) + " · " + statusText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(DesignTokens.Colors.green.opacity(0.14))
                                .clipShape(Capsule())
                        }

                        RingProgressView(
                            consumed: viewModel.proteinConsumed,
                            goal: viewModel.proteinGoal
                        )
                        .frame(height: 210)

                        HStack(spacing: 0) {
                            HomeStatColumn(
                                value: String(format: "%.0fg", viewModel.proteinConsumed),
                                label: "GEGETEN",
                                color: DesignTokens.Colors.green
                            )
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 36)
                            HomeStatColumn(
                                value: String(format: "%.0fg", viewModel.proteinGoal),
                                label: "DOEL",
                                color: DesignTokens.Colors.text
                            )
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 36)
                            HomeStatColumn(
                                value: String(format: "%.0fg", viewModel.remaining),
                                label: "TE GAAN",
                                color: DesignTokens.Colors.tomato
                            )
                        }
                    }
                }

                // ── Steps card ────────────────────────────────────────
                StyledCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DesignTokens.Colors.surface2)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 15))
                                    .foregroundColor(DesignTokens.Colors.textMuted)
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text("BEWEGING")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.textMuted)
                                    .tracking(0.7)
                                Text("Mijn stappen")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.text)
                            }
                            Spacer()
                            Text(healthManager.isAuthorized ? "✓ Gekoppeld" : "Niet gekoppeld")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(healthManager.isAuthorized
                                    ? DesignTokens.Colors.green
                                    : DesignTokens.Colors.tomato)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(formattedSteps(healthManager.steps))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(DesignTokens.Colors.green)
                                .monospacedDigit()
                            Text("van 10.000")
                                .font(.system(size: 14))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                            Spacer()
                            Text(String(format: "%.0f%%", min((Double(healthManager.steps) / 10000) * 100, 100)))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(DesignTokens.Colors.text)
                                .monospacedDigit()
                        }

                        StepDotBar(steps: Int(healthManager.steps), goal: 10000)
                    }
                }

                // ── Log card ──────────────────────────────────────────
                StyledCard {
                    VStack(spacing: DesignTokens.Spacing.md) {

                        HStack {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(DesignTokens.Colors.green)
                                Text("Noteer eiwit")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.text)
                            }
                            Spacer()
                            Text("SNEL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                                .tracking(0.7)
                        }

                        // Input row
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .fill(DesignTokens.Colors.surface2)

                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    if viewModel.proteinInput.isEmpty {
                                        Text("gram")
                                            .font(.system(size: 22, weight: .light))
                                            .foregroundColor(DesignTokens.Colors.textDim)
                                    } else {
                                        Text(viewModel.proteinInput)
                                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                            .foregroundColor(DesignTokens.Colors.text)
                                        Text("gram")
                                            .font(.system(size: 14))
                                            .foregroundColor(DesignTokens.Colors.textMuted)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                                .allowsHitTesting(false)

                                TextField("", text: $viewModel.proteinInput)
                                    .keyboardType(.decimalPad)
                                    .focused($proteinInputFocused)
                                    .opacity(0.01)
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                            .frame(height: 58)
                            .onChange(of: viewModel.proteinInput) {
                                let filtered = viewModel.proteinInput.filter { "0123456789.".contains($0) }
                                if filtered.filter({ $0 == "." }).count > 1 {
                                    viewModel.proteinInput = String(filtered.prefix(while: { $0 != "." }))
                                        + "."
                                        + filtered.drop(while: { $0 != "." }).dropFirst().filter({ $0 != "." })
                                } else {
                                    viewModel.proteinInput = filtered
                                }
                            }
                            .onTapGesture { proteinInputFocused = true }

                            Button(action: { viewModel.addProtein() }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(DesignTokens.Colors.background)
                                    .frame(width: 58, height: 58)
                                    .background(DesignTokens.Colors.green)
                                    .cornerRadius(DesignTokens.Radius.md)
                            }
                        }

                        // Quick chips
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach([10, 20, 30, 50], id: \.self) { amount in
                                Button {
                                    viewModel.proteinInput = String(amount)
                                    viewModel.addProtein()
                                } label: {
                                    Text("+\(amount)g")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.green)
                                        .padding(.horizontal, DesignTokens.Spacing.md)
                                        .padding(.vertical, DesignTokens.Spacing.sm)
                                        .background(DesignTokens.Colors.green.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                        }

                        // Action buttons
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Button(action: { showProteinPicker = true }) {
                                HStack(spacing: DesignTokens.Spacing.sm) {
                                    Image(systemName: "list.bullet")
                                    Text("Kies voedsel")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignTokens.Spacing.md)
                                .background(DesignTokens.Colors.surface2)
                                .foregroundColor(DesignTokens.Colors.text)
                                .cornerRadius(DesignTokens.Radius.md)
                            }

                            Button(action: { startScanFlow() }) {
                                HStack(spacing: DesignTokens.Spacing.sm) {
                                    Image(systemName: "barcode.viewfinder")
                                    Text("Scan")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignTokens.Spacing.md)
                                .background(DesignTokens.Colors.surface2)
                                .foregroundColor(DesignTokens.Colors.text)
                                .cornerRadius(DesignTokens.Radius.md)
                            }
                        }
                    }
                }

                Spacer(minLength: DesignTokens.Spacing.xxl)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            Task { await healthManager.fetchTodayData() }
        }
        .onTapGesture { proteinInputFocused = false }
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
                        proteinInputFocused = true
                    },
                    onCancel: { activeScanSheet = nil }
                )
            }
        }
    }
}

// MARK: - Private sub-views

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
                .foregroundColor(DesignTokens.Colors.textMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ScanErrorView: View {
    let message: String
    let allowsManualEntry: Bool
    let onRetry: () -> Void
    let onManualEntry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                StyledCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        SectionLabel("Scannen", icon: "exclamationmark.triangle.fill")
                        Text(message)
                            .font(.system(size: 15))
                            .foregroundColor(DesignTokens.Colors.text)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                VStack(spacing: DesignTokens.Spacing.md) {
                    PrimaryButton(title: "Probeer opnieuw", icon: "arrow.clockwise", action: onRetry, color: DesignTokens.Colors.green)
                    if allowsManualEntry {
                        Button(action: onManualEntry) {
                            Text("Vul handmatig in")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.accent)
                        }
                    }
                    Button(action: onCancel) {
                        Text("Annuleer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textMuted)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.background)
            .navigationTitle("Scan fout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

private struct ScanLoadingView: View {
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                StyledCard {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        ProgressView()
                            .tint(DesignTokens.Colors.accent)
                        Text("Product opzoeken")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.text)
                        Text("We halen de eiwitwaarden op uit Open Food Facts.")
                            .font(.system(size: 14))
                            .foregroundColor(DesignTokens.Colors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                Button(action: onCancel) {
                    Text("Annuleer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textMuted)
                }

                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.background)
            .navigationTitle("Zoeken")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProteinViewModel(
            diaryRepository: SupabaseDiaryRepository(),
            userProfileRepository: SupabaseUserProfileRepository()
        ))
        .environmentObject(AccountViewModel(
            userProfileRepository: SupabaseUserProfileRepository()
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(HealthManager())
}
