import SwiftUI

struct ScanResultView: View {
    let product: FoodProduct
    let onConfirm: (Double) -> Void
    let onCancel: () -> Void

    @State private var portionInput: String

    init(product: FoodProduct, onConfirm: @escaping (Double) -> Void, onCancel: @escaping () -> Void) {
        self.product = product
        self.onConfirm = onConfirm
        self.onCancel = onCancel

        let initialPortion = product.servingSizeGrams ?? 100
        _portionInput = State(initialValue: String(format: "%.0f", initialPortion))
    }

    private var portionValue: Double {
        let normalized = portionInput.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var totalProtein: Double {
        guard portionValue > 0 else { return 0 }
        return (portionValue / 100) * product.proteinPer100g
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    StyledCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            SectionLabel("Gescand product", icon: "barcode.viewfinder")
                            Text(product.name)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.text)

                            Text("\(String(format: "%.1f", product.proteinPer100g))g eiwit per 100g")
                                .font(.system(size: 15))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    StyledCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            SectionLabel("Portie", icon: "scalemass")

                            TextInput(
                                label: "Portie",
                                text: $portionInput,
                                placeholder: "100",
                                unit: "g",
                                keyboard: .decimal
                            )
                            .onChange(of: portionInput) {
                                let normalized = portionInput.replacingOccurrences(of: ",", with: ".")
                                let filtered = normalized.filter { "0123456789.".contains($0) }
                                if filtered != normalized {
                                    portionInput = filtered
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(0.08))

                            HStack {
                                Text("Totaal")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.textMuted)
                                Spacer()
                                Text("\(String(format: "%.2f", totalProtein))g eiwit")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.green)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    VStack(spacing: DesignTokens.Spacing.md) {
                        PrimaryButton(title: "Voeg toe aan vandaag", icon: "plus.circle.fill", action: {
                            onConfirm(portionValue)
                        }, color: DesignTokens.Colors.green, isDisabled: portionValue <= 0)

                        Button(action: onCancel) {
                            Text("Annuleer")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Scan resultaat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
