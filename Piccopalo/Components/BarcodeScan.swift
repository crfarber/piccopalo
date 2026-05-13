import SwiftUI

private struct ScanErrorView: View {
    let message: String
    let allowsManualEntry: Bool
    let onRetry: () -> Void
    let onManualEntry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Spacing.lg) {
                StyledCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionLabel("Scannen", icon: "exclamationmark.triangle.fill")
                        Text(message)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.md) {
                    PrimaryButton(title: "Probeer opnieuw", icon: "arrow.clockwise", action: onRetry, color: Theme.Colors.green)
                    if allowsManualEntry {
                        Button(action: onManualEntry) {
                            Text("Vul handmatig in")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.accent)
                        }
                    }
                    Button(action: onCancel) {
                        Text("Annuleer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
            .padding(.top, Theme.Spacing.lg)
            .background(Theme.Colors.background)
            .navigationTitle("Scan fout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

private struct ScanLoadingView: View {
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Spacing.lg) {
                StyledCard {
                    VStack(spacing: Theme.Spacing.md) {
                        ProgressView()
                            .tint(Theme.Colors.accent)
                        Text("Product opzoeken")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        Text("We halen de eiwitwaarden op uit Open Food Facts.")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Button(action: onCancel) {
                    Text("Annuleer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()
            }
            .padding(.top, Theme.Spacing.lg)
            .background(Theme.Colors.background)
            .navigationTitle("Zoeken")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
