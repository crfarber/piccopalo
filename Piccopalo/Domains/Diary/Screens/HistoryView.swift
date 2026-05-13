import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
    @State private var records: [DayRecord] = []

    private var recordsByDate: [String: DayRecord] {
        Dictionary(uniqueKeysWithValues: records.map { ($0.date, $0) })
    }

    private var lastSevenDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { i in
            cal.date(byAdding: .day, value: i - 6, to: today)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    weekStrip
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.md)

                    if records.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, Theme.Spacing.xxl)
                    } else {
                        StyledCard {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Alle dagen")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(0.4)
                                    .textCase(.uppercase)
                                    .foregroundStyle(Theme.Colors.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, Theme.Spacing.md)

                                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                    NavigationLink(destination: DayDetailView(record: record)) {
                                        HistoryRowView(record: record)
                                    }
                                    .buttonStyle(.plain)

                                    if index < records.count - 1 {
                                        Divider()
                                            .background(Color.white.opacity(0.08))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .task {
                await reloadRecords()
            }
            .onReceive(NotificationCenter.default.publisher(for: .piccopaloAccountDidChange)) { _ in
                Task { await reloadRecords() }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Geschiedenis")
                    .font(.custom(Theme.Typography.displayFont, size: 34, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.Colors.cream)

                Text("De laatste 7 dagen")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.Colors.text)
            }
            .accessibilityLabel("Kalender")
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var weekStrip: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(lastSevenDays, id: \.self) { date in
                let key = HistoryFormatting.isoString(from: date)
                let consumed = recordsByDate[key]?.proteinConsumed ?? 0
                let goal = recordsByDate[key]?.proteinGoal ?? viewModel.proteinGoal
                let percentage = goal > 0 ? min((consumed / goal) * 100, 100) : 0
                HistoryWeekDayColumn(date: date, percentage: percentage)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("📅")
                .font(.system(size: 56))
            Text("Nog geen data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.text)
            Text("Voeg vandaag je eerste eiwitinname toe!")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
    }

    private func reloadRecords() async {
        records = await viewModel.allRecords()
    }
}

// MARK: - Week strip

private struct HistoryWeekDayColumn: View {
    let date: Date
    let percentage: Double

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(HistoryFormatting.weekStripLabel(for: date))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Colors.textMuted)

            VerticalProgressBar(
                percentage: percentage,
                width: 14,
                height: 52,
                cornerRadius: 6,
                style: .statusTint,
                showGlow: false,
                outlineLineWidth: 1,
                outlineOpacity: 0.16
            )

            Text("\(Int(round(percentage)))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colors.text)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Row

struct HistoryRowView: View {
    let record: DayRecord

    private var percentage: Double {
        guard record.proteinGoal > 0 else { return 0 }
        return min((record.proteinConsumed / record.proteinGoal) * 100, 100)
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VerticalProgressBar(
                percentage: percentage,
                width: 15,
                height: 56,
                cornerRadius: 6,
                style: .statusTint,
                showGlow: false,
                outlineLineWidth: 1,
                outlineOpacity: 0.16
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(HistoryFormatting.primaryDayLabel(isoDate: record.date))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.text)

                    Text(HistoryFormatting.dayAndMonthNL(isoDate: record.date))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                }

                Text("\(grams(record.proteinConsumed))g van \(grams(record.proteinGoal))g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textMuted)
                
                if let stepsCount = record.stepsCount, stepsCount > 0 {
                    Text("\(Int(round(stepsCount))) stappen")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.green)
                }
            }

            Spacer(minLength: 8)

            Text("\(Int(round(percentage)))%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.text)
                .monospacedDigit()
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func grams(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}

