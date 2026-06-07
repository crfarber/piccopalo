import SwiftUI

struct TextInput: View {
    enum KeyboardKind {
        case text
        case ascii
        case integer
        case decimal
        case phone
        case email
        case url
    }

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var placeholderColor: Color = Theme.Colors.textDim
    var unit: String? = nil
    var keyboard: KeyboardKind = .text
    var isSecure: Bool = false
    var textAlignment: TextAlignment = .leading
    var textInputAutocapitalization: TextInputAutocapitalization? = nil
    var disableAutocorrection: Bool? = nil
    var submitLabel: SubmitLabel? = nil
    var onSubmit: (() -> Void)? = nil
    /// Optioneel: koppel aan `@FocusState` in de parent om het keyboard te sluiten (bijv. bij tik buiten het veld).
    var fieldFocus: FocusState<Bool>.Binding?
    @FocusState private var isLocallyFocused: Bool

    private var fieldFont: Font {
        .system(size: 18, weight: .semibold)
    }

    var body: some View {
        let isActive = fieldFocus?.wrappedValue ?? isLocallyFocused

        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                Group {
                    if isSecure {
                        if placeholder.isEmpty {
                            SecureField("", text: $text)
                        } else {
                            SecureField("", text: $text, prompt:
                                Text(placeholder)
                                    .font(fieldFont)
                                    .foregroundStyle(placeholderColor)
                            )
                        }
                    } else {
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
                }
                    .optionalFocused(fieldFocus, fallback: $isLocallyFocused)
                    .textInputKeyboard(keyboard)
                    .optionalTextInputAutocapitalization(textInputAutocapitalization)
                    .optionalAutocorrectionDisabled(disableAutocorrection)
                    .optionalSubmitLabel(submitLabel)
                    .optionalOnSubmit(onSubmit)
                    .font(fieldFont)
                    .foregroundStyle(Theme.Colors.text)
                    .multilineTextAlignment(textAlignment)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.Colors.surface2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.Colors.cream.opacity(isActive ? 0.7 : 0), lineWidth: 1.2)
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: isActive)

                if let unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
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

    @ViewBuilder
    func optionalTextInputAutocapitalization(_ value: TextInputAutocapitalization?) -> some View {
        if let value {
            self.textInputAutocapitalization(value)
        } else {
            self
        }
    }

    @ViewBuilder
    func optionalAutocorrectionDisabled(_ value: Bool?) -> some View {
        if let value {
            self.autocorrectionDisabled(value)
        } else {
            self
        }
    }

    @ViewBuilder
    func optionalSubmitLabel(_ label: SubmitLabel?) -> some View {
        if let label {
            self.submitLabel(label)
        } else {
            self
        }
    }

    @ViewBuilder
    func optionalOnSubmit(_ action: (() -> Void)?) -> some View {
        if let action {
            self.onSubmit(action)
        } else {
            self
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
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}
