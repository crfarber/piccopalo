import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()

                // Logo / titel
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Piccopalo")
                        .font(.custom(DesignTokens.Typography.displayFont, size: 40))
                        .foregroundColor(DesignTokens.Colors.cream)

                    Text(isSignUp ? "Maak een account aan" : "Welkom terug")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(DesignTokens.Colors.textMuted)
                }

                Spacer()

                // Formulier
                VStack(spacing: DesignTokens.Spacing.md) {
                    inputField(
                        label: "E-mailadres",
                        text: $email,
                        keyboard: .emailAddress,
                        isSecure: false
                    )

                    inputField(
                        label: "Wachtwoord",
                        text: $password,
                        keyboard: .default,
                        isSecure: true
                    )

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(DesignTokens.Colors.tomato)
                            .multilineTextAlignment(.center)
                            .padding(.top, DesignTokens.Spacing.xs)
                    }
                }

                // Actieknop
                PrimaryButton(
                    title: isSignUp ? "Registreren" : "Inloggen",
                    icon: nil,
                    action: {
                        Task {
                            if isSignUp {
                                await authViewModel.signUp(email: email, password: password)
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    },
                    isDisabled: email.isEmpty || password.isEmpty || authViewModel.isLoading
                )

                // Wisselen tussen inloggen en registreren
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        authViewModel.errorMessage = nil
                    }
                } label: {
                    Text(isSignUp
                         ? "Al een account? **Inloggen**"
                         : "Nog geen account? **Registreren**")
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.Colors.textMuted)
                }

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)

            if authViewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(DesignTokens.Colors.cream)
                    .scaleEffect(1.4)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func inputField(
        label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textMuted)

            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.surface)
            .foregroundColor(DesignTokens.Colors.text)
            .cornerRadius(DesignTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
