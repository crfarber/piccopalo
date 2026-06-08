import SwiftUI

/// Multi-select picker uit de oefeningen-bibliotheek. Gebruikt in schema-bewerken en tijdens een sessie.
struct ExercisePickerSheet: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel
    @Environment(\.dismiss) private var dismiss

    /// Oefeningen die al in de lijst staan en niet opnieuw gekozen kunnen worden.
    var excludedIds: Set<UUID> = []
    let onAdd: ([Exercise]) -> Void

    @State private var searchText = ""
    @State private var selectedIds: Set<UUID> = []

    private var filteredByCategory: [(category: ExerciseCategory, items: [Exercise])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ExerciseCategory.allCases.compactMap { category in
            let items = fitnessViewModel.exercises
                .filter { $0.category == category && !excludedIds.contains($0.id) }
                .filter { query.isEmpty || $0.name.lowercased().contains(query) }
                .sorted { $0.name < $1.name }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredByCategory, id: \.category) { group in
                    Section {
                        ForEach(group.items) { exercise in
                            Button {
                                toggle(exercise)
                            } label: {
                                HStack(spacing: Theme.Spacing.md) {
                                    ExerciseThumbnailView(exercise: exercise, size: 32)
                                    Text(exercise.name)
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                    Spacer()
                                    if selectedIds.contains(exercise.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.Colors.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(Theme.Colors.textDim)
                                    }
                                }
                            }
                            .listRowBackground(Theme.Colors.surface)
                        }
                    } header: {
                        Label(group.category.label, systemImage: group.category.icon)
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Oefeningen kiezen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Zoek oefening...")
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: selectedIds.isEmpty ? "Toevoegen" : "Toevoegen (\(selectedIds.count))",
                    icon: "plus.circle.fill",
                    action: confirm,
                    color: Theme.Colors.green,
                    isDisabled: selectedIds.isEmpty
                )
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.background)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleer") { dismiss() }
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .task {
            if fitnessViewModel.exercises.isEmpty {
                await fitnessViewModel.loadExercises()
            }
        }
    }

    private func toggle(_ exercise: Exercise) {
        if selectedIds.contains(exercise.id) {
            selectedIds.remove(exercise.id)
        } else {
            selectedIds.insert(exercise.id)
        }
    }

    private func confirm() {
        let chosen = fitnessViewModel.exercises.filter { selectedIds.contains($0.id) }
        onAdd(chosen)
        dismiss()
    }
}
