import SwiftUI

struct TextInput: View {
    /// Welk toetsenbord tonen — kies wat past bij je data (String / Int / Double / …).
    enum KeyboardKind {
        /// Algemene tekst
        case text
        /// Alleen ASCII
        case ascii
        /// Gehele getallen — geen decimaal
        case integer
        /// Kommagetallen
        case decimal
        /// Telefoon
        case phone
        /// E-mail
        case email
        /// URL
        case url
    }

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var placeholderColor: Color = DesignTokens.Colors.textDim
    let unit: String?
    var keyboard: KeyboardKind = .text
    /// Optioneel: koppel aan `@FocusState` in de parent om het keyboard te sluiten (bijv. bij tik buiten het veld).
    var fieldFocus: FocusState<Bool>.Binding?
    @FocusState private var isLocallyFocused: Bool

    private var fieldFont: Font {
        .system(size: 18, weight: .semibold)
    }

    var body: some View {
        let isActive = fieldFocus?.wrappedValue ?? isLocallyFocused

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }

            HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
                Group {
                    if placeholder.isEmpty {
                        TextField("", text: $text)
                    } else {
                        TextField("", text: $text, prompt:
                            Text(placeholder)
                                .font(fieldFont)
                                .foregroundStyle(placeholderColor)
                        )
                    }
                }
                    .optionalFocused(fieldFocus, fallback: $isLocallyFocused)
                    .textInputKeyboard(keyboard)
                    .font(fieldFont)
                    .foregroundStyle(DesignTokens.Colors.text)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DesignTokens.Colors.surface2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(DesignTokens.Colors.cream.opacity(isActive ? 0.7 : 0), lineWidth: 1.2)
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: isActive)

                if let unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                        .fixedSize()
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func optionalFocused(_ binding: FocusState<Bool>.Binding?, fallback: FocusState<Bool>.Binding) -> some View {
        if let binding {
            self.focused(binding)
        } else {
            self.focused(fallback)
        }
    }

    @ViewBuilder
    func textInputKeyboard(_ kind: TextInput.KeyboardKind) -> some View {
        switch kind {
        case .text:    self.keyboardType(.default)
        case .ascii:   self.keyboardType(.asciiCapable)
        case .integer: self.keyboardType(.numberPad)
        case .decimal: self.keyboardType(.decimalPad)
        case .phone:   self.keyboardType(.phonePad)
        case .email:   self.keyboardType(.emailAddress)
        case .url:     self.keyboardType(.URL)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var goal: String = "120"
        @State private var name: String = "Alex"
        @State private var weight: String = "72.5"
        var body: some View {
            VStack(spacing: 20) {
                TextInput(label: "Eiwitdoel", text: $goal, placeholder: "0", unit: "g/dag", keyboard: .integer)
                TextInput(label: "Naam", text: $name, placeholder: "Jouw naam", unit: nil, keyboard: .text)
                TextInput(label: "Gewicht", text: $weight, placeholder: "0", unit: "kg", keyboard: .decimal)
            }
            .padding()
            .background(DesignTokens.Colors.background)
        }
    }
    return PreviewWrapper()
}
