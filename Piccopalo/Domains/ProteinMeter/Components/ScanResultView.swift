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

    private var totalCarbs: Double? {
        guard portionValue > 0, let carbs = product.carbsPer100g else { return nil }
        return (portionValue / 100) * carbs
    }

    private var giBadge: some View {
        let category = product.glycemicCategory
        return HStack(spacing: 4) {
            Text(category.emoji)
                .font(.system(size: 12))
            Text(category.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(category.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(category.color.opacity(0.14))
        .clipShape(Capsule())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    StyledCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            SectionLabel("Gescand product", icon: "barcode.viewfinder")
                            Text(product.name)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            Text("\(String(format: "%.1f", product.proteinPer100g))g eiwit per 100g")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.Colors.textMuted)

                            HStack(spacing: Theme.Spacing.sm) {
                                giBadge
                                if let carbs = product.carbsPer100g {
                                    Text("\(String(format: "%.0f", carbs))g KH/100g")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.Colors.textMuted)
                                }
                            }
                            .padding(.top, Theme.Spacing.xs)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    StyledCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
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
                                    .foregroundColor(Theme.Colors.textMuted)
                                Spacer()
                                Text("\(String(format: "%.2f", totalProtein))g eiwit")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(Theme.Colors.green)
                            }

                            if let carbs = totalCarbs {
                                HStack {
                                    Text("Koolhydraten")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.textMuted)
                                    Spacer()
                                    Text("\(String(format: "%.0f", carbs))g")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.Colors.text)
                                }
                            }

                            if let gl = product.glycemicLoad(forPortionGrams: portionValue) {
                                HStack {
                                    Text("Glycemische lading")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.textMuted)
                                    Spacer()
                                    Text(String(format: "%.0f", gl))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.Colors.text)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    VStack(spacing: Theme.Spacing.md) {
                        PrimaryButton(title: "Voeg toe aan vandaag", icon: "plus.circle.fill", action: {
                            onConfirm(portionValue)
                        }, color: Theme.Colors.green, isDisabled: portionValue <= 0)

                        AppButton(
                            title: "Annuleer",
                            icon: nil,
                            size: .fullWidth,
                            background: Theme.Colors.surface2,
                            foreground: Theme.Colors.textMuted,
                            cornerStyle: .rounded(Theme.Radius.md),
                            action: onCancel
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
                .padding(.vertical, Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Scan resultaat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
