import SwiftUI

struct WaterSettingsView: View {
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State private var waterGoalValue: Double
    @Environment(\.dismiss) var dismiss

    init() {
        _waterGoalValue = State(initialValue: 2000)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.blue.opacity(0.2))
                                .frame(width: 86, height: 86)

                            Image(systemName: "drop.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.Colors.blue)
                        }

                        Text("Waterdoel")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)

                        Text("Stel je dagelijkse waterdoel in")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)

                    // Water goal section
                    VStack(spacing: Theme.Spacing.md) {
                        SectionLabel("Dagdoel", icon: "target")

                        StyledCard {
                            VStack(spacing: Theme.Spacing.lg) {
                                // Current goal display
                                HStack(spacing: Theme.Spacing.md) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Huidig doel")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textMuted)
                                            .tracking(0.4)
                                            .textCase(.uppercase)

                                        HStack(spacing: 4) {
                                            Text(String(Int(waterGoalValue)))
                                                .font(.system(size: 28, weight: .semibold))
                                                .foregroundStyle(Theme.Colors.text)
                                            Text("ml/dag")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Theme.Colors.textMuted)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.Colors.blue)
                                }
                                .padding(.vertical, Theme.Spacing.md)

                                Divider()
                                    .background(Color.white.opacity(0.08))

                                // Slider
                                VStack(spacing: Theme.Spacing.md) {
                                    Slider(
                                        value: $waterGoalValue,
                                        in: 500...4000,
                                        step: 100,
                                        label: { Text("ml") }
                                    )
                                    .tint(Theme.Colors.blue)

                                    HStack(spacing: Theme.Spacing.md) {
                                        Text("500 ml")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textMuted)
                                        Spacer()
                                        Text("4000 ml")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textMuted)
                                    }
                                }
                                .padding(.vertical, Theme.Spacing.sm)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Information section
                    VStack(spacing: Theme.Spacing.md) {
                        SectionLabel("Aanbeveling", icon: "info.circle.fill")

                        StyledCard {
                            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                HStack(spacing: Theme.Spacing.md) {
                                    Image(systemName: "heart.text.square.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Theme.Colors.green)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Type 1 Diabetes")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textMuted)
                                            .tracking(0.4)
                                            .textCase(.uppercase)

                                        Text("Voor iemand met diabetes type 1 wordt minimaal 2 liter (2000ml) water per dag aangeraden.")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Theme.Colors.text)
                                            .lineLimit(nil)
                                    }
                                }

                                Divider()
                                    .background(Color.white.opacity(0.08))

                                HStack(spacing: Theme.Spacing.md) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Theme.Colors.cream)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Tip")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textMuted)
                                            .tracking(0.4)
                                            .textCase(.uppercase)

                                        Text("Verdeel je waterdoel over de dag. Bijvoorbeeld 4 glazen van 500ml verspreid over de dag.")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Theme.Colors.text)
                                            .lineLimit(nil)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Action buttons
                    VStack(spacing: Theme.Spacing.md) {
                        AppButton(
                            title: "Opslaan",
                            icon: nil,
                            size: .fullWidth,
                            background: Theme.Colors.blue,
                            foreground: Theme.Colors.background,
                            cornerStyle: .rounded(Theme.Radius.md),
                            action: { saveWaterGoal() }
                        )

                        AppButton(
                            title: "Annuleer",
                            icon: nil,
                            size: .fullWidth,
                            background: Theme.Colors.surface2,
                            foreground: Theme.Colors.text,
                            cornerStyle: .rounded(Theme.Radius.md),
                            action: { dismiss() }
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Spacer()
                        .frame(height: Theme.Spacing.lg)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }
            .onAppear {
                waterGoalValue = Double(proteinViewModel.waterGoal)
            }
        }
    }

    private func saveWaterGoal() {
        proteinViewModel.waterGoal = Int(waterGoalValue)
        // Save to UserDefaults (will be persisted to Supabase via AccountViewModel)
        UserDefaults.standard.set(Int(waterGoalValue), forKey: "waterGoalMl")
        dismiss()
    }
}

#Preview {
    WaterSettingsView()
        .environmentObject(ProteinViewModel(
            diaryRepository: SupabaseDiaryRepository(),
            userProfileRepository: SupabaseUserProfileRepository(),
            waterRepository: SupabaseWaterRepository()
        ))
        .preferredColorScheme(.dark)
}
