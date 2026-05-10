import SwiftUI

struct ProteinSourcePickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProteinViewModel

    @State private var searchText = ""
    @State private var selectedSource: ProteinSource?
    @State private var consumedQuantity: String = ""

    var filteredSources: [ProteinSource] {
        if searchText.isEmpty {
            return defaultProteinSources
        }
        return defaultProteinSources.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var quantityValue: Double {
        let normalized = consumedQuantity.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var calculatedProtein: Double {
        guard let source = selectedSource, quantityValue > 0 else { return 0 }
        return (quantityValue / 100) * source.proteinPer100g
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()

                if selectedSource == nil {
                    // List of sources
                    List(filteredSources) { source in
                        Button(action: {
                            selectedSource = source
                            consumedQuantity = ""
                        }) {
                            HStack {
                                Text(source.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(String(format: "%.1f", source.proteinPer100g))g / 100\(source.unit.symbol)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    // Adjustment screen
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Selected Food")
                                    .font(.caption).foregroundColor(.secondary)
                                HStack {
                                    Text(selectedSource!.name)
                                        .font(.headline)
                                    Spacer()
                                    Button(action: { selectedSource = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Consumed Amount")
                                    .font(.headline)

                                HStack {
                                    TextField("0", text: $consumedQuantity)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.title3)

                                    Text(selectedSource!.unit.symbol)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                Text("Nutrition: \(String(format: "%.1f", selectedSource!.proteinPer100g))g protein per 100\(selectedSource!.unit.symbol)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("Calculated protein: \(String(format: "%.1f", calculatedProtein))g")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            .padding()

                            Button(action: addAndDismiss) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add To Today")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(quantityValue <= 0)

                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(selectedSource == nil ? "Choose Food" : "Add Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addAndDismiss() {
        guard let source = selectedSource, quantityValue > 0 else { return }
        viewModel.addProtein(source: source, quantity: quantityValue)
        dismiss()
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search foods", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

