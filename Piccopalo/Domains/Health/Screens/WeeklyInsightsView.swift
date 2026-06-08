import SwiftUI

struct WeeklyInsightsView: View {
    @EnvironmentObject var healthViewModel: HealthViewModel
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @EnvironmentObject var healthManager: HealthManager

    @State private var insight: WeeklyInsight = .empty
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if isLoading {
                        ProgressView()
                            .tint(Theme.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Theme.Spacing.xxl)
                    } else if !insight.hasEnoughData {
                        notEnoughDataCard
                    } else {
                        bloodSugarSection
                        if insight.showsGIComparison {
                            giImpactSection
                        }
                        if insight.activityDataAvailable,
                           insight.avgBSHighActivity != nil || insight.avgBSLowActivity != nil {
                            activitySection
                        }
                        if insight.avgDailyCarbs != nil {
                            carbsSection
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.lg)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Jouw inzichten")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await load() }
    }

    // MARK: - Sections

    private var notEnoughDataCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Nog niet genoeg data", icon: "hourglass")
                Text("Voeg meer metingen toe voor inzichten. Je hebt \(insight.bsDataPoints) van de \(WeeklyInsight.minimumReadings) benodigde metingen.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textMuted)
            }
        }
    }

    private var bloodSugarSection: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Bloedsuiker deze week", icon: "drop.fill")

                if let avg = insight.avgDailyBS {
                    statRow(label: "Gemiddelde", value: String(format: "%.1f mmol/L", avg), color: Theme.Colors.text)
                }
                if let minBS = insight.minBS, let maxBS = insight.maxBS {
                    statRow(
                        label: "Bereik",
                        value: String(format: "%.1f – %.1f mmol/L", minBS, maxBS),
                        color: Theme.Colors.textMuted
                    )
                }
                statRow(label: "Aantal metingen", value: "\(insight.bsDataPoints)", color: Theme.Colors.textMuted)
            }
        }
    }

    private var giImpactSection: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("GI impact", icon: "chart.bar.fill")

                if let high = insight.avgBSChangeAfterHighGI {
                    Text("Na hoog-GI eten steeg je bloedsuiker gemiddeld \(String(format: "%.1f", high)) punten.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.text)
                }
                if let low = insight.avgBSChangeAfterLowGI {
                    Text("Na laag-GI eten was dat gemiddeld \(String(format: "%.1f", low)) punten.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
    }

    private var activitySection: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Activiteit effect", icon: "figure.walk")

                if let active = insight.avgBSHighActivity {
                    statRow(label: "Actieve dagen", value: String(format: "%.1f mmol/L", active), color: Theme.Colors.green)
                }
                if let quiet = insight.avgBSLowActivity {
                    statRow(label: "Rustige dagen", value: String(format: "%.1f mmol/L", quiet), color: Theme.Colors.text)
                }
            }
        }
    }

    private var carbsSection: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionLabel("Koolhydraten", icon: "leaf.fill")

                if let carbs = insight.avgDailyCarbs {
                    statRow(label: "Gemiddeld per dag", value: String(format: "%.0f g", carbs), color: Theme.Colors.text)
                }
            }
        }
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - Loading

    private func load() async {
        isLoading = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        // Maaltijden van de afgelopen 7 dagen verzamelen uit de dagrecords.
        let weekIsoDates = Set((0..<7).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HealthViewModel.isoFormatter.string(from: date)
        })

        let records = await proteinViewModel.allRecords()
        let meals = records
            .filter { weekIsoDates.contains($0.date) }
            .flatMap { $0.entries }

        let stepCounts = healthManager.isAuthorized
            ? await healthManager.fetchDailyStepCounts(from: weekStart, to: today)
            : [:]

        insight = await healthViewModel.weeklyInsight(meals: meals, stepCounts: stepCounts)
        isLoading = false
    }
}
