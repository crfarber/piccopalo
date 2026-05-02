import SwiftUI

struct ProteinSourcePickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProteinViewModel

    @State private var searchText = ""
    @State private var selectedSource: ProteinSource?
    @State private var customProtein: String = ""

    var filteredSources: [ProteinSource] {
        if searchText.isEmpty {
            return defaultProteinSources
        }
        return defaultProteinSources.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                        Button(action: { selectedSource = source }) {
                            HStack {
                                Text(source.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(String(format: "%.0f", source.proteinPer100g))g")
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
                                Text("Protein Amount (grams)")
                                    .font(.headline)

                                HStack {
                                    TextField("0", text: $customProtein)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.title3)

                                    Text("g")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                Text("Default: \(String(format: "%.0f", selectedSource!.proteinPer100g))g per 100g")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()

                            Button(action: addAndDismiss) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Protein")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(customProtein.isEmpty || (Double(customProtein) ?? 0) <= 0)

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
        let amount = Double(customProtein) ?? 0
        guard amount > 0 else { return }

        viewModel.proteinInput = String(format: "%.0f", amount)
        viewModel.addProtein()
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

#Preview {
    ProteinSourcePickerView(viewModel: ProteinViewModel())
}
