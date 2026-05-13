import SwiftUI

struct FormMenuRow<Option, ID: Hashable>: View {
    let title: String
    let selectionText: String
    let options: [Option]
    let id: KeyPath<Option, ID>
    let optionLabel: (Option) -> String
    let onSelect: (Option) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: id) { option in
                Button(optionLabel(option)) {
                    onSelect(option)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(Theme.Colors.textMuted)

                Spacer()

                HStack(spacing: Theme.Spacing.sm) {
                    Text(selectionText)
                        .foregroundStyle(Theme.Colors.text)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.cream)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .tint(Theme.Colors.cream)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
