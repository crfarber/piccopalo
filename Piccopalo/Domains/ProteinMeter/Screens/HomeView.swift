import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
    @FocusState private var proteinInputFocused: Bool
    @State private var showProteinPicker = false

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.proteinGoal > 0 {
                            // Pasta jar - hero section
                            VStack(spacing: DesignTokens.Spacing.md) {
                                ProgressBar(percentage: viewModel.percentage, size: 180, showGlow: true)

                                // Stats
                                HStack(spacing: DesignTokens.Spacing.xl) {
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
                            }
                            .padding(.bottom, DesignTokens.Spacing.xxl)
                        }

                        // Input section
                        VStack(spacing: DesignTokens.Spacing.md) {
                            SectionLabel("Add Protein", icon: "plus.circle.fill")

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
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }
                        .padding(.bottom, DesignTokens.Spacing.xxl)

                        // Details
                        if viewModel.proteinGoal > 0 {
                            VStack(spacing: DesignTokens.Spacing.md) {
                                SectionLabel("Details", icon: "chart.bar.fill")

                                StyledCard {
                                    VStack(spacing: 0) {
                                        DetailRow("Percentage", String(format: "%.0f%%", viewModel.percentage))
                                        Divider()
                                            .background(Color.white.opacity(0.08))
                                        DetailRow("Progress", "", color: DesignTokens.Colors.text)

                                        StyledProgressBar(percentage: viewModel.percentage)
                                            .padding(.top, DesignTokens.Spacing.md)

                                        Text(viewModel.message(for: viewModel.percentage))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(DesignTokens.Colors.green)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, DesignTokens.Spacing.md)
                                    }
                                }
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                        }

                        Spacer()
                            .frame(height: DesignTokens.Spacing.xxl)
                    }
                }
                .navigationBarHidden(true)
                .scrollContentBackground(.hidden) // iOS 16+
                .background(DesignTokens.Colors.background)
                .scrollDismissesKeyboard(.immediately)
            }
            .onTapGesture {
                proteinInputFocused = false
            }
            .sheet(isPresented: $showProteinPicker) {
                ProteinSourcePickerView(viewModel: viewModel)
            }
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.textMuted)
                .tracking(0.4)
                .textCase(.uppercase)

            Text(value + "g")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    let (container, protein, _) = PersistenceController.previewStack()
    HomeView()
        .environmentObject(protein)
        .modelContainer(container)
}
