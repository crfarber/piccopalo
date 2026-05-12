import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
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

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            StyledCard {
                                VStack(spacing: DesignTokens.Spacing.md) {
                                    Text("Mijn  protein")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.text)


                                    HStack(spacing: DesignTokens.Spacing.md) {
                                        StatBox(
                                            label: "Gegeten",
                                            value: String(format: "%.0f", viewModel.proteinConsumed),
                                            color: DesignTokens.Colors.green
                                        )
                                        StatBox(
                                            label: "Doel",
                                            value: String(format: "%.0f", viewModel.proteinGoal),
                                            color: DesignTokens.Colors.text
                                        )
                                        StatBox(
                                            label: "Te gaan",
                                            value: String(format: "%.0f", viewModel.remaining),
                                            color: DesignTokens.Colors.tomato
                                        )
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                                    StyledProgressBar(percentage: viewModel.percentage)
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }
                        .padding(.bottom, DesignTokens.Spacing.md)

                        Spacer()
                            .frame(height: DesignTokens.Spacing.xxl)

                        // Stappen section
                        VStack(spacing: DesignTokens.Spacing.md) {
                            StyledCard {
                                VStack(spacing: DesignTokens.Spacing.md) {
                                    Text("Mijn stappen")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.text)

                                    HStack(spacing: DesignTokens.Spacing.md) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(Int(healthManager.steps))")
                                                .font(.system(size: 28, weight: .semibold))
                                                .foregroundColor(DesignTokens.Colors.green)

                                            Text("van 10.000 stappen")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(DesignTokens.Colors.textMuted)
                                                .tracking(0.4)
                                                .textCase(.uppercase)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(String(format: "%.0f%%", (Double(healthManager.steps) / 10000) * 100))
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(DesignTokens.Colors.green)

                                            if healthManager.isAuthorized {
                                                Text("✓ Gekoppeld")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(DesignTokens.Colors.green)
                                            } else {
                                                Text("Niet gekoppeld")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(DesignTokens.Colors.tomato)
                                            }
                                        }
                                    }
                                    
                                    StyledProgressBar(percentage: (Double(healthManager.steps) / 10000) * 100)

                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }
                        .padding(.bottom, DesignTokens.Spacing.xxl)

                        Spacer()
                            .frame(height: DesignTokens.Spacing.xxl)

                        VStack(spacing: DesignTokens.Spacing.md) {
                            StyledCard {
                                VStack(spacing: DesignTokens.Spacing.md) {
                                    HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
                                        TextInput(label: "Noteer eiwit", text: $viewModel.proteinInput, placeholder: "Hoeveel gram?", unit: "", keyboard: .decimal, fieldFocus: $proteinInputFocused)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .onChange(of: viewModel.proteinInput) {
                                                let filtered = viewModel.proteinInput.filter { "0123456789.".contains($0) }
                                                if filtered.filter({ $0 == "." }).count > 1 {
                                                    let first = filtered.prefix { $0 != "." } + filtered.drop { $0 != "." }.prefix(while: { $0 == "." }) + filtered.drop { $0 != "." }.drop(while: { $0 == "." }).filter { $0 != "." }
                                                    viewModel.proteinInput = String(first)
                                                } else {
                                                    viewModel.proteinInput = filtered
                                                }
                                            }

                                        Button(action: { viewModel.addProtein() }, label: { Text("+") })
                                            .fontWeight(.semibold)
                                            .foregroundColor(DesignTokens.Colors.text)
                                            .frame(width: 44)
                                            .padding(.vertical, DesignTokens.Spacing.sm)
                                            .background(DesignTokens.Colors.green)
                                            .cornerRadius(DesignTokens.Radius.md)
                                    }

                                    Button(action: { showProteinPicker = true }) {
                                        HStack(spacing: DesignTokens.Spacing.sm) {
                                            Image(systemName: "list.bullet")
                                            Text("Choose food")
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(DesignTokens.Spacing.md)
                                        .background(DesignTokens.Colors.surface2)
                                        .foregroundColor(DesignTokens.Colors.green)
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
                                        .foregroundColor(DesignTokens.Colors.green)
                                        .cornerRadius(DesignTokens.Radius.md)
                                    }
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }
                        .padding(.bottom, DesignTokens.Spacing.xxl)


                }
            }
            .scrollContentBackground(.hidden) // iOS 16+
            .background(DesignTokens.Colors.background)
            .scrollDismissesKeyboard(.immediately)
            .onAppear {
                Task {
                    await healthManager.fetchTodayData()
                }
            }
            .onTapGesture {
                proteinInputFocused = false
            }
            .sheet(isPresented: $showProteinPicker) {
                ProteinSourcePickerView(viewModel: viewModel)
            }
            .sheet(item: $activeScanSheet) { sheet in
                switch sheet.kind {
                case .scanner:
                    BarcodeScannerView(
                        onScan: { code in
                            handleScannedBarcode(code)
                        },
                        onCancel: {
                            activeScanSheet = nil
                        },
                        onFailure: { message in
                            activeScanSheet = ScanSheetState(
                                kind: .error(message: message, allowsManualEntry: true)
                            )
                        }
                    )
                case .loading:
                    ScanLoadingView(onCancel: {
                        activeScanSheet = nil
                    })
                case let .result(product):
                    ScanResultView(
                        product: product,
                        onConfirm: { quantity in
                            applyScannedProduct(product, quantity: quantity)
                        },
                        onCancel: {
                            activeScanSheet = nil
                        }
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

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value + "g")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(color)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.textMuted)
                .tracking(0.4)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
