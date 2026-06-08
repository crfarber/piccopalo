import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel

    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var openSwipeID: String?

    private var filteredByCategory: [(category: ExerciseCategory, items: [Exercise])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ExerciseCategory.allCases.compactMap { category in
            let items = fitnessViewModel.exercises
                .filter { $0.category == category }
                .filter { query.isEmpty || $0.name.lowercased().contains(query) }
                .sorted { $0.name < $1.name }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        List {
            if filteredByCategory.isEmpty {
                emptyState
            } else {
                ForEach(filteredByCategory, id: \.category) { group in
                    Section {
                        ForEach(group.items) { exercise in
                            Group {
                                if exercise.isCustom {
                                    SwipeableActionRow(
                                        id: exercise.id.uuidString,
                                        openID: $openSwipeID,
                                        onDelete: {
                                            Task { await fitnessViewModel.deleteCustomExercise(exercise) }
                                        }
                                    ) {
                                        ExerciseRow(exercise: exercise)
                                            .padding(.horizontal, Theme.Spacing.lg)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Theme.Colors.surface)
                                    }
                                } else if exerciseShowsDetail(exercise) {
                                    NavigationLink {
                                        ExerciseDetailView(exercise: exercise)
                                    } label: {
                                        ExerciseRow(exercise: exercise)
                                    }
                                } else {
                                    ExerciseRow(exercise: exercise)
                                }
                            }
                            .listRowInsets(exercise.isCustom ? EdgeInsets() : nil)
                            .listRowBackground(exercise.isCustom ? Color.clear : Theme.Colors.surface)
                            .listRowSeparator(exercise.isCustom ? .hidden : .automatic)
                        }
                    } header: {
                        Label(group.category.label, systemImage: group.category.icon)
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Oefeningen")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Zoek oefening...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Theme.Colors.green)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddExerciseSheet { name, category in
                Task { await fitnessViewModel.addCustomExercise(name: name, category: category) }
            }
            .adaptiveBottomSheet()
        }
        .task {
            if fitnessViewModel.exercises.isEmpty {
                await fitnessViewModel.loadExercises()
            }
            if fitnessViewModel.exercises.isEmpty {
                await ExerciseImportService(
                    exerciseRepository: SupabaseExerciseRepository(),
                    fitnessViewModel: fitnessViewModel
                ).seedIfNeeded()
            }
        }
        .alert(
            "Er ging iets mis",
            isPresented: Binding(
                get: { fitnessViewModel.errorMessage != nil },
                set: { if !$0 { fitnessViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { fitnessViewModel.errorMessage = nil }
        } message: {
            Text(fitnessViewModel.errorMessage ?? "")
        }
    }

    private var emptyState: some View {
        Text(searchText.isEmpty ? "Nog geen oefeningen" : "Geen oefeningen gevonden")
            .font(.system(size: 15))
            .foregroundColor(Theme.Colors.textMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
            .padding(.vertical, Theme.Spacing.xl)
    }

    private func exerciseShowsDetail(_ exercise: Exercise) -> Bool {
        !exercise.isCustom && (
            exercise.instructions != nil
            || exercise.thumbnailPath != nil
            || exercise.sourceId != nil
        )
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ExerciseThumbnailView(exercise: exercise, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)

                if !exercise.difficultyLabel.isEmpty {
                    Text(exercise.difficultyLabel)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }

            Spacer()

            if exercise.isCustom {
                Text("Eigen")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.green)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.green.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
    }
}

struct AddExerciseSheet: View {
    let onAdd: (String, ExerciseCategory) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ExerciseCategory = .borst
    @FocusState private var isNameFocused: Bool

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionLabel("Eigen oefening toevoegen", icon: "plus.circle.fill")

            TextInput(
                label: "Naam oefening",
                text: $name,
                placeholder: "Naam oefening",
                keyboard: .text,
                fieldFocus: $isNameFocused
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Categorie")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(ExerciseCategory.allCases) { option in
                            Pill(
                                title: option.label,
                                isActive: category == option,
                                action: { category = option }
                            )
                        }
                    }
                }
            }

            PrimaryButton(
                title: "Toevoegen",
                icon: "checkmark.circle.fill",
                action: {
                    onAdd(name, category)
                    dismiss()
                },
                color: Theme.Colors.green,
                isDisabled: !canAdd
            )
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveSheetContentHeight()
        .background(Theme.Colors.background)
        .onAppear { isNameFocused = true }
    }
}
