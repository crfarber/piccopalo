import SwiftUI

struct WorkoutTemplatesView: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if fitnessViewModel.templates.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.xxl * 2)
                } else {
                    StyledCard {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(fitnessViewModel.templates.enumerated()), id: \.element.id) { index, template in
                                NavigationLink {
                                    WorkoutTemplateView(template: template)
                                } label: {
                                    TemplateRow(template: template)
                                }
                                .buttonStyle(.plain)

                                if index < fitnessViewModel.templates.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Schema's")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.green)
                        .frame(width: 42, height: 42)
                        .background(Theme.Colors.surface2)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Nieuw schema")
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateTemplateSheet { name in
                Task { _ = await fitnessViewModel.createTemplate(name: name, dayOfWeek: nil) }
            }
            .adaptiveBottomSheet()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 36))
                .foregroundColor(Theme.Colors.textMuted)

            Text("Nog geen schema's")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.text)

            Text("Maak een schema met oefeningen. Koppel het daarna aan een dag via het weekoverzicht.")
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            PrimaryButton(
                title: "Schema aanmaken",
                icon: "plus.circle.fill",
                action: { showCreateSheet = true },
                color: Theme.Colors.green
            )
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.sm)
        }
    }
}

private struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.green)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                Text(template.planLabel)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}

struct CreateTemplateSheet: View {
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionLabel("Nieuw schema", icon: "plus.circle.fill")

            TextInput(
                label: "Naam",
                text: $name,
                placeholder: "Bijv. Push dag",
                keyboard: .text,
                fieldFocus: $isNameFocused
            )

            PrimaryButton(
                title: "Aanmaken",
                icon: "checkmark.circle.fill",
                action: {
                    onCreate(name)
                    dismiss()
                },
                color: Theme.Colors.green,
                isDisabled: !canCreate
            )
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveSheetContentHeight()
        .background(Theme.Colors.background)
        .onAppear { isNameFocused = true }
    }
}
