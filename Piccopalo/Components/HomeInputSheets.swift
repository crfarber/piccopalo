import SwiftUI

struct HomeFoodSheet: View {
    let amounts: [Int]
    @Binding var text: String
    var fieldFocus: FocusState<Bool>.Binding
    let onQuickAdd: (Int) -> Void
    let onCustomAdd: () -> Void
    let onPickFood: () -> Void
    let onScan: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Voedsel")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.lg)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(amounts, id: \.self) { amount in
                    Button {
                        onQuickAdd(amount)
                    } label: {
                        Text("\(amount) g")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                                    .fill(Theme.Colors.green.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            HStack(spacing: Theme.Spacing.sm) {
                TextInput(
                    label: "Vrij invoer",
                    text: $text,
                    placeholder: "bijv. 25",
                    unit: "g",
                    keyboard: .decimal,
                    fieldFocus: fieldFocus
                )
                .onChange(of: text) {
                    let filtered = text.filter { "0123456789.,".contains($0) }
                    if filtered.filter({ $0 == "." || $0 == "," }).count > 1 {
                        let normalized = filtered.replacingOccurrences(of: ",", with: ".")
                        text = String(normalized.prefix(while: { $0 != "." }))
                            + "."
                            + normalized.drop(while: { $0 != "." }).dropFirst().filter { $0 != "." }
                    } else {
                        text = filtered
                    }
                }

                AppButton(
                    title: nil,
                    icon: "plus",
                    size: .square(58),
                    background: Theme.Colors.green,
                    foreground: Theme.Colors.background,
                    cornerStyle: .rounded(Theme.Radius.md),
                    action: onCustomAdd
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                secondaryRow(icon: "list.bullet", title: "Kies voedsel", action: onPickFood)
                secondaryRow(icon: "barcode.viewfinder", title: "Scan", action: onScan)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .adaptiveSheetContentHeight()
    }

    private func secondaryRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.green)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HomeWaterSheet: View {
    let amounts: [Int]
    @Binding var text: String
    var fieldFocus: FocusState<Bool>.Binding
    let onQuickAdd: (Int) -> Void
    let onCustomAdd: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Water")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.lg)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(amounts, id: \.self) { amount in
                    Button {
                        onQuickAdd(amount)
                    } label: {
                        Text("\(amount) ml")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                                    .fill(Theme.Colors.blue.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            HStack(spacing: Theme.Spacing.sm) {
                TextInput(
                    label: "Vrij invoer",
                    text: $text,
                    placeholder: "bijv. 300",
                    unit: "ml",
                    keyboard: .integer,
                    fieldFocus: fieldFocus
                )
                .onChange(of: text) {
                    text = text.filter { $0.isNumber }
                }

                AppButton(
                    title: nil,
                    icon: "plus",
                    size: .square(58),
                    background: Theme.Colors.blue,
                    foreground: Theme.Colors.background,
                    cornerStyle: .rounded(Theme.Radius.md),
                    action: onCustomAdd
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .adaptiveSheetContentHeight()
    }
}
