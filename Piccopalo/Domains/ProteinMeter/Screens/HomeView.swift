import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ProteinViewModel
    @FocusState private var focusedField: Field?
    @State private var showProteinPicker = false

    private enum Field { case protein }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    eiwitSection
                    resultatenSection
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .onTapGesture { focusedField = nil }
            .sheet(isPresented: $showProteinPicker) {
                ProteinSourcePickerView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(spacing: 12) {
            Text("🍝")
                .font(.system(size: 44))
            VStack(alignment: .leading, spacing: 2) {
                Text("Piccopalo")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(.green)
                Text("Jouw dagelijkse eiwittracker")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var eiwitSection: some View {
        GroupBox(label: Label("Eiwit", systemImage: "dumbbell.fill")) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    TextField("Gram", text: $viewModel.proteinInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .protein)

                    Button(action: {
                        viewModel.addProtein()
                        focusedField = nil
                    }) {
                        Text("+")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(Color.green)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        viewModel.subtractProtein()
                        focusedField = nil
                    }) {
                        Text("−")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showProteinPicker = true }) {
                Label("Eiwit", systemImage: "carrot.fill")
                    .font(.body)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var resultatenSection: some View {
        GroupBox(label: Label("Vandaag", systemImage: "chart.bar.fill")) {
            VStack(spacing: 12) {
                ResultRow(label: "Dagdoel", value: "\(formatted(viewModel.proteinGoal))g", color: .primary)
                Divider()
                ResultRow(label: "Gegeten", value: "\(formatted(viewModel.proteinConsumed))g", color: .green)
                Divider()
                ResultRow(label: "Nog te gaan", value: "\(formatted(viewModel.remaining))g", color: .orange)
                Divider()
                ResultRow(label: "Percentage", value: "\(formatted(viewModel.percentage))%", color: .primary)

                ProgressBarView(percentage: viewModel.percentage)
                    .padding(.top, 6)

                Text(viewModel.message(for: viewModel.percentage))
                    .font(.headline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}

private struct ResultRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.bold).foregroundColor(color)
        }
    }
}
