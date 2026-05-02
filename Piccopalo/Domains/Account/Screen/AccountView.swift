import SwiftUI

struct AccountView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @FocusState private var focusedField: Field?
    @State private var showProteinPicker = false

    private enum Field { case weight, protein }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    gegevensSection
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .onTapGesture { focusedField = nil }
            .onChange(of: accountViewModel.weight) { _ in
                accountViewModel.saveUser()
            }
        }
    }

    private var gegevensSection: some View {
        GroupBox(label: Label("Jouw gegevens", systemImage: "person.fill")) {
            VStack(spacing: 14) {
                HStack {
                    Text("Gewicht (kg)")
                    Spacer()
                    TextField("0", value: $accountViewModel.weight, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .weight)
                }
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

#Preview("AccountView") {
    AccountView()
        .environmentObject(AccountViewModel())
}
