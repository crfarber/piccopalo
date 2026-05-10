import SwiftUI
import UIKit

struct HealthDetailsView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var accountViewModel: AccountViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    private func refreshHealthData() async {
        healthManager.refreshAuthorizationStatus()
        await healthManager.fetchTodayData()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                if !healthManager.isAuthorized {
                    // Authorization required
                    StyledCard {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 32))
                                .foregroundColor(DesignTokens.Colors.accent)

                            Text("Gezondheidsgegevens")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.text)

                            Text("Geef Piccopalo toestemming om je gezondheidsgegevens te lezen uit de Health-app.")
                                .font(.system(size: 13))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                                .multilineTextAlignment(.center)

                            Text("Zie je geen opties in iOS Instellingen? Open dan de Health-app > Profiel > Apps > Piccopalo.")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                                .multilineTextAlignment(.center)

                            Button(action: {
                                Task {
                                    await healthManager.requestAuthorization()
                                }
                            }) {
                                Text("Geef Toestemming")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignTokens.Spacing.md)
                                    .background(DesignTokens.Colors.accent)
                                    .cornerRadius(8)
                            }

                            Button {
                                Task {
                                    await refreshHealthData()
                                }
                            } label: {
                                Text("Ververs gegevens")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignTokens.Spacing.sm)
                            }

                            Button {
                                if let healthURL = URL(string: "x-apple-health://") {
                                    openURL(healthURL)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "heart.text.square.fill")
                                    Text("Open Health-app")
                                        .font(.system(size: 14, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .foregroundColor(DesignTokens.Colors.accent)
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                } else {
                    // Health data cards
                    VStack(spacing: DesignTokens.Spacing.md) {
                        SectionLabel("Vandaag", icon: "calendar")
                        
                        // Activity Suggestion Card
                        StyledCard {
                            VStack(spacing: DesignTokens.Spacing.md) {
                                HStack {
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                        Text("Aanbevolen activiteit (7 dagen)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(DesignTokens.Colors.textMuted)
                                            .tracking(0.4)
                                            .textCase(.uppercase)
                                        
                                        Text(healthManager.getActivityLevel())
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(DesignTokens.Colors.text)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(DesignTokens.Colors.accent)
                                }

                                Text("Gebaseerd op je weekgemiddelde (70%) en vandaag (30%).")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    accountViewModel.activityFactor = healthManager.calculateActivityFactor()
                                    accountViewModel.saveAccount()
                                    dismiss()
                                }) {
                                    Text("Overnemen")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DesignTokens.Spacing.md)
                                        .background(DesignTokens.Colors.accent)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        // Data cards
                        HealthDataCard(
                            icon: "figure.walk",
                            title: "Stappen",
                            value: "\(healthManager.steps)",
                            unit: "stappen"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        HealthDataCard(
                            icon: "flame.fill",
                            title: "Actieve energie",
                            value: String(format: "%.0f", healthManager.activeEnergy),
                            unit: "kcal"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        HealthDataCard(
                            icon: "heart.fill",
                            title: "Oefentijd",
                            value: "\(healthManager.exerciseTime)",
                            unit: "minuten"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        HealthDataCard(
                            icon: "figure.stairs",
                            title: "Afstand",
                            value: String(format: "%.1f", healthManager.distance),
                            unit: "km"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        HealthDataCard(
                            icon: "arrow.up.right",
                            title: "Verdiepingen beklommen",
                            value: "\(healthManager.flightsClimbed)",
                            unit: "verdiepingen"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        SectionLabel("Weekgemiddelde", icon: "chart.line.uptrend.xyaxis")

                        HealthDataCard(
                            icon: "figure.walk",
                            title: "Gem. stappen",
                            value: "\(healthManager.weeklyAverageSteps)",
                            unit: "per dag"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        HealthDataCard(
                            icon: "flame.fill",
                            title: "Gem. actieve energie",
                            value: String(format: "%.0f", healthManager.weeklyAverageActiveEnergy),
                            unit: "kcal/dag"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        HealthDataCard(
                            icon: "heart.fill",
                            title: "Gem. oefentijd",
                            value: "\(healthManager.weeklyAverageExerciseTime)",
                            unit: "min/dag"
                        )
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                    
                    // Last updated
                    if let lastUpdated = healthManager.lastUpdated {
                        Text("Geüpdatet: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 11))
                            .foregroundColor(DesignTokens.Colors.textMuted)
                            .padding(.top, DesignTokens.Spacing.lg)
                    }
                }

                StyledCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Health toegang")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textMuted)
                            .tracking(0.4)
                            .textCase(.uppercase)

                        Text("Toegang wijzigen: Health-app > Profiel > Apps > Piccopalo.")
                            .font(.system(size: 13))
                            .foregroundColor(DesignTokens.Colors.textMuted)

                        if healthManager.canRequestAuthorization {
                            Text("Nog niet afgerond: tik op 'Geef Toestemming'.")
                                .font(.system(size: 13))
                                .foregroundColor(DesignTokens.Colors.warning)
                        } else {
                            Text("Autorisatie aangevraagd. Ververs als je net toestemming hebt aangepast.")
                                .font(.system(size: 13))
                                .foregroundColor(DesignTokens.Colors.green)
                        }

                        Button {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            openURL(settingsURL)
                        } label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Open app-instellingen")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundColor(DesignTokens.Colors.accent)
                            .padding(.top, DesignTokens.Spacing.sm)
                        }

                        Button {
                            if let healthURL = URL(string: "x-apple-health://") {
                                openURL(healthURL)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "heart.text.square.fill")
                                Text("Open Health-app")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundColor(DesignTokens.Colors.accent)
                            .padding(.top, DesignTokens.Spacing.xs)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)

                if let errorMessage = healthManager.errorMessage {
                    StyledCard {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignTokens.Colors.warning)
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.warning)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }

                if let diagnostics = healthManager.diagnostics {
                    StyledCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Debug")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                                .tracking(0.4)
                                .textCase(.uppercase)

                            Text(diagnostics)
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textMuted)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                
                Spacer(minLength: DesignTokens.Spacing.lg)
            }
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
        .navigationTitle("Gezondheid")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignTokens.Colors.background)
        .refreshable {
            await refreshHealthData()
        }
        .onAppear {
            Task {
                await refreshHealthData()
            }
        }
    }
}

struct HealthDataCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        StyledCard {
            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textMuted)
                        .tracking(0.4)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.text)
                        Text(unit)
                            .font(.system(size: 13))
                            .foregroundColor(DesignTokens.Colors.textMuted)
                    }
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.Colors.accent)
            }
        }
    }
}

#Preview {
    HealthDetailsView()
        .environmentObject(HealthManager())
        .environmentObject(AccountViewModel(userProfileRepository: UserProfileRepositoryMock()))
}
