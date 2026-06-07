import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Logo / titel
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Piccopalo")
                        .font(.custom(Theme.Typography.displayFont, size: 40))
                        .foregroundColor(Theme.Colors.cream)

                    Text(isSignUp ? "Maak een account aan" : "Welkom terug")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()

                // Formulier
                VStack(spacing: Theme.Spacing.md) {
                    TextInput(
                        label: "E-mailadres",
                        text: $email,
                        placeholder: "naam@voorbeeld.nl",
                        keyboard: .email,
                        isSecure: false,
                        textInputAutocapitalization: .never,
                        disableAutocorrection: true,
                        submitLabel: .next
                    )

                    TextInput(
                        label: "Wachtwoord",
                        text: $password,
                        placeholder: "Vul je wachtwoord in",
                        keyboard: .ascii,
                        isSecure: true,
                        textInputAutocapitalization: .never,
                        disableAutocorrection: true,
                        submitLabel: .done
                    )

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.tomato)
                            .multilineTextAlignment(.center)
                            .padding(.top, Theme.Spacing.xs)
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
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            if authViewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(Theme.Colors.cream)
                    .scaleEffect(1.4)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
