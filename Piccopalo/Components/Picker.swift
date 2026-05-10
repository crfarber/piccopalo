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
                    .foregroundColor(DesignTokens.Colors.textMuted)

                Spacer()

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(selectionText)
                        .foregroundStyle(DesignTokens.Colors.text)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.cream)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignTokens.Spacing.md)
            .contentShape(Rectangle())
        }
        .tint(DesignTokens.Colors.cream)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}