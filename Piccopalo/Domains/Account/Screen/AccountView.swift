import SwiftUI

struct AccountView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notificationStore = NotificationStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Theme.Colors.cream,
                                        Theme.Colors.creamDeep
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 86, height: 86)

                        Text(String(accountViewModel.name.prefix(1)))
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    .padding(.top, Theme.Spacing.lg)

                    Text(accountViewModel.name)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, Theme.Spacing.xxl)

                // Your data section
                VStack(spacing: Theme.Spacing.md) {
                    SectionLabel("Jouw gegevens", icon: "person.fill")

                    StyledCard {
                        VStack(spacing: 0) {
                            AccountInputRow(
                                title: "Naam",
                                text: $accountViewModel.name,
                                placeholder: "Naam",
                                keyboard: .text,
                                submitLabel: .next,
                                onSubmit: { accountViewModel.saveAccount() }
                            )
                            .padding(.vertical, Theme.Spacing.md)

                            Divider()
                                .background(Color.white.opacity(0.08))

                            AccountInputRow(
                                title: "Gewicht (kg)",
                                text: $accountViewModel.weight,
                                placeholder: "0",
                                keyboard: .decimal,
                                submitLabel: .next,
                                onSubmit: { accountViewModel.saveAccount() }
                            )
                            .padding(.vertical, Theme.Spacing.md)

                            Divider()
                                .background(Color.white.opacity(0.08))

                            AccountInputRow(
                                title: "Lengte (cm)",
                                text: $accountViewModel.height,
                                placeholder: "0",
                                keyboard: .decimal,
                                submitLabel: .done,
                                onSubmit: { accountViewModel.saveAccount() }
                            )
                            .padding(.vertical, Theme.Spacing.md)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                // Health section
                VStack(spacing: Theme.Spacing.md) {
                    SectionLabel("Gezondheid", icon: "heart.fill")

                    StyledCard {
                        NavigationLink(destination: HealthDetailsView()) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(Theme.Colors.accent)

                                Text("Gezondheidsgegevens")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textMuted)
                            }
                            .padding(.vertical, Theme.Spacing.md)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
                .padding(.top, Theme.Spacing.xl)

                // Logout
                StyledCard {
                    Button {
                        Task { await authViewModel.signOut() }
                    } label: {
                        HStack {
                            Text("Uitloggen")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.tomato)
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Theme.Colors.tomato)
                        }
                        .padding(.vertical, Theme.Spacing.md)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.xl)

                Spacer()
                    .frame(height: Theme.Spacing.xl)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Theme.Colors.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                }
                .accessibilityLabel("Terug")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: NotificationInboxView()) {
                    notificationBellButton
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: accountViewModel.name) { accountViewModel.saveAccount() }
        .onChange(of: accountViewModel.weight) { accountViewModel.saveAccount() }
        .onChange(of: accountViewModel.height) { accountViewModel.saveAccount() }
    }

    private var notificationBellButton: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .frame(width: 42, height: 42)
                .background(Theme.Colors.surface2)
                .clipShape(Circle())

            if notificationStore.unreadCount > 0 {
                Circle()
                    .fill(Theme.Colors.tomato)
                    .frame(width: 9, height: 9)
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: 42, height: 42)
    }
}

private struct AccountInputRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboard: TextInput.KeyboardKind
    let submitLabel: SubmitLabel
    let onSubmit: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Theme.Colors.textMuted)

            Spacer()

            TextInput(
                label: "",
                text: $text,
                placeholder: placeholder,
                keyboard: keyboard,
                textAlignment: .trailing,
                textInputAutocapitalization: .never,
                disableAutocorrection: true,
                submitLabel: submitLabel,
                onSubmit: onSubmit
            )
            .frame(maxWidth: 170)
        }
    }
}

