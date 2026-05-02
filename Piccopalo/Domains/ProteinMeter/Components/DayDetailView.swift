import SwiftUI

struct DayDetailView: View {
    @State private var currentRecord: DayRecord
    @State private var proteinConsumedInput: String

    init(record: DayRecord) {
        _currentRecord = State(initialValue: record)
        _proteinConsumedInput = State(initialValue: String(format: "%.0f", record.proteinConsumed))
    }

    private var percentage: Double {
        guard currentRecord.proteinGoal > 0 else { return 0 }
        return min((currentRecord.proteinConsumed / currentRecord.proteinGoal) * 100, 100)
    }

    private var activityLabel: String {
        switch currentRecord.activityFactor {
        case 0.8:  return "Weinig beweging"
        case 1.2:  return "Licht actief"
        case 1.4:  return "Regelmatig sporten"
        case 1.6:  return "Intensief trainen"
        default:   return String(format: "%.1f", currentRecord.activityFactor)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(currentRecord.date)
                    .font(.title2).fontWeight(.semibold)
                    .padding(.top)

                GroupBox(label: Label("Gegevens", systemImage: "person.fill")) {
                    VStack(spacing: 10) {
                        DetailRow(label: "Gewicht", value: String(format: "%.1f kg", currentRecord.weight))
                        Divider()
                        DetailRow(label: "Activiteit", value: activityLabel)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)

                GroupBox(label: Label("Resultaten", systemImage: "chart.bar.fill")) {
                    VStack(spacing: 10) {
                        DetailRow(label: "Eiwitdoel", value: String(format: "%.0fg", currentRecord.proteinGoal))
                        Divider()
                        DetailRow(label: "Eiwit gegeten", value: String(format: "%.0fg", currentRecord.proteinConsumed))
                        Divider()
                        DetailRow(label: "Percentage", value: String(format: "%.0f%%", percentage))

                        ProgressBarView(percentage: percentage)
                            .padding(.top, 6)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)

                GroupBox(label: Label("Handmatig aanpassen", systemImage: "square.and.pencil")) {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            TextField("Gegeten gram", text: $proteinConsumedInput)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("Opslaan") {
                                saveManualUpdate()
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }

                        Text("Pas alleen deze dag aan. Je kunt fouten achteraf corrigeren.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveManualUpdate() {
        guard let value = Double(proteinConsumedInput), value >= 0 else { return }
        currentRecord.proteinConsumed = value
        StorageManager.shared.saveRecord(for: currentRecord.date, record: currentRecord)
        proteinConsumedInput = String(format: "%.0f", value)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}
