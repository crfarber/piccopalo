import SwiftUI

struct WorkoutTemplateView: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate

    @State private var name: String
    @State private var items: [WorkoutTemplateExercise] = []
    @State private var showPicker = false
    @State private var editingItem: WorkoutTemplateExercise?
    @State private var isLoading = true
    @FocusState private var isNameFocused: Bool

    init(template: WorkoutTemplate) {
        self.template = template
        _name = State(initialValue: template.name)
    }

    var body: some View {
        List {
            detailsSection
            exercisesSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Schema")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .tint(Theme.Colors.green)
            }
        }
        .task {
            await reloadItems()
            isLoading = false
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet(
                excludedIds: Set(items.map { $0.exerciseId })
            ) { chosen in
                Task { await add(chosen) }
            }
        }
        .sheet(item: $editingItem) { item in
            TargetEditSheet(item: item) { updated in
                Task { await updateTarget(updated) }
            }
            .adaptiveBottomSheet()
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        Section {
            HStack {
                Text("Naam")
                    .foregroundColor(Theme.Colors.textMuted)
                Spacer()
                TextField("Bijv. Push dag", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Theme.Colors.text)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit { Task { await saveDetails() } }
            }
            .listRowBackground(Theme.Colors.surface)
        }
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        Section {
            if isLoading {
                ProgressView()
                    .tint(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if items.isEmpty {
                Text("Nog geen oefeningen. Voeg er een toe.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textMuted)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(items) { item in
                    Button {
                        editingItem = item
                    } label: {
                        TemplateExerciseRow(item: item)
                    }
                    .listRowBackground(Theme.Colors.surface)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }

            Button {
                showPicker = true
            } label: {
                Label("Oefening toevoegen", systemImage: "plus.circle.fill")
                    .foregroundColor(Theme.Colors.green)
            }
            .listRowBackground(Theme.Colors.surface)
        } header: {
            Text("Oefeningen")
                .foregroundColor(Theme.Colors.textMuted)
        }
    }

    // MARK: - Actions

    private func reloadItems() async {
        items = await fitnessViewModel.templateExercises(for: template.id)
    }

    private func saveDetails() async {
        var updated = template
        updated.name = name
        await fitnessViewModel.updateTemplate(updated)
    }

    private func add(_ exercises: [Exercise]) async {
        var order = items.count
        for exercise in exercises {
            await fitnessViewModel.addExercise(exercise, to: template.id, sortOrder: order)
            order += 1
        }
        await reloadItems()
    }

    private func deleteItems(_ offsets: IndexSet) {
        let toRemove = offsets.map { items[$0] }
        items.remove(atOffsets: offsets)
        Task {
            for item in toRemove {
                await fitnessViewModel.removeTemplateExercise(item)
            }
        }
    }

    private func moveItems(_ source: IndexSet, _ destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        let reordered = items
        Task { await fitnessViewModel.reorderTemplateExercises(reordered) }
    }

    private func updateTarget(_ updated: WorkoutTemplateExercise) async {
        if let index = items.firstIndex(where: { $0.id == updated.id }) {
            items[index] = updated
        }
        await fitnessViewModel.updateTemplateExercise(updated)
    }
}

private struct TemplateExerciseRow: View {
    let item: WorkoutTemplateExercise

    private var targetSummary: String {
        var parts: [String] = []
        if let sets = item.targetSets, let reps = item.targetReps {
            parts.append("\(sets)×\(reps)")
        } else if let sets = item.targetSets {
            parts.append("\(sets) sets")
        } else if let reps = item.targetReps {
            parts.append("\(reps) reps")
        }
        if let kg = item.targetWeightKg {
            parts.append("\(PreviousSetSummary.formatKg(kg)) kg")
        }
        if let rest = item.targetRestSeconds {
            parts.append("\(rest)s rust")
        }
        return parts.isEmpty ? "Geen doelen ingesteld" : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.exercise?.name ?? "Onbekende oefening")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                Text(targetSummary)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textDim)
        }
    }
}

private struct TargetEditSheet: View {
    let item: WorkoutTemplateExercise
    let onSave: (WorkoutTemplateExercise) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var setsText: String
    @State private var repsText: String
    @State private var weightText: String
    @State private var restText: String

    init(item: WorkoutTemplateExercise, onSave: @escaping (WorkoutTemplateExercise) -> Void) {
        self.item = item
        self.onSave = onSave
        _setsText = State(initialValue: item.targetSets.map(String.init) ?? "")
        _repsText = State(initialValue: item.targetReps.map(String.init) ?? "")
        _weightText = State(initialValue: item.targetWeightKg.map { PreviousSetSummary.formatKg($0) } ?? "")
        _restText = State(initialValue: item.targetRestSeconds.map(String.init) ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionLabel(item.exercise?.name ?? "Doelen", icon: "target")

            HStack(spacing: Theme.Spacing.md) {
                TextInput(label: "Sets", text: $setsText, placeholder: "3", keyboard: .integer)
                TextInput(label: "Reps", text: $repsText, placeholder: "8", keyboard: .integer)
            }
            HStack(spacing: Theme.Spacing.md) {
                TextInput(label: "Gewicht", text: $weightText, placeholder: "60", unit: "kg", keyboard: .decimal)
                TextInput(label: "Rust", text: $restText, placeholder: "90", unit: "s", keyboard: .integer)
            }

            PrimaryButton(
                title: "Opslaan",
                icon: "checkmark.circle.fill",
                action: save,
                color: Theme.Colors.green
            )
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveSheetContentHeight()
        .background(Theme.Colors.background)
    }

    private func save() {
        var updated = item
        updated.targetSets = Int(setsText.trimmingCharacters(in: .whitespaces))
        updated.targetReps = Int(repsText.trimmingCharacters(in: .whitespaces))
        updated.targetWeightKg = Double(weightText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        updated.targetRestSeconds = Int(restText.trimmingCharacters(in: .whitespaces))
        onSave(updated)
        dismiss()
    }
}
