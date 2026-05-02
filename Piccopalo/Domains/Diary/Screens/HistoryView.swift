import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: ProteinViewModel

    var records: [DayRecord] {
        viewModel.allRecords()
    }

    var body: some View {
        NavigationView {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List(records) { record in
                        NavigationLink(destination: DayDetailView(record: record)) {
                            HistoryRowView(record: record)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Geschiedenis")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📅")
                .font(.system(size: 60))
            Text("Nog geen data")
                .font(.title2).fontWeight(.semibold)
            Text("Voeg vandaag je eerste eiwitinname toe!")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct HistoryRowView: View {
    let record: DayRecord

    private var percentage: Double {
        guard record.proteinGoal > 0 else { return 0 }
        return min((record.proteinConsumed / record.proteinGoal) * 100, 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.date)
                .font(.headline)
            HStack {
                Text("Doel: \(formatted(record.proteinGoal))g")
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text("Gegeten: \(formatted(record.proteinConsumed))g")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            ProgressBarView(percentage: percentage)
                .frame(height: 10)
            Text("\(formatted(percentage))%")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}
