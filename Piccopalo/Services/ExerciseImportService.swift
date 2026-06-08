import Foundation

@MainActor
final class ExerciseImportService {
    enum ImportError: LocalizedError {
        case bundleFileNotFound
        case notAuthenticated
        case noExercisesImported

        var errorDescription: String? {
            switch self {
            case .bundleFileNotFound:
                return "exercises_filtered.json niet gevonden in de app-bundle."
            case .notAuthenticated:
                return "Inloggen vereist voor oefeningen-import."
            case .noExercisesImported:
                return "Geen oefeningen opgeslagen. Controleer of migratie 004 op Supabase is gedraaid."
            }
        }
    }

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let fitnessViewModel: FitnessViewModel
    private let defaults = UserDefaults.standard
    private let seededKey = "exerciseLibrarySeeded_v1"
    private let batchSize = 50
    private let seedThreshold = 50

    init(
        exerciseRepository: ExerciseRepositoryProtocol,
        fitnessViewModel: FitnessViewModel
    ) {
        self.exerciseRepository = exerciseRepository
        self.fitnessViewModel = fitnessViewModel
    }

    func seedIfNeeded() async {
        await healSeedFlagIfDatabaseEmpty()

        guard !defaults.bool(forKey: seededKey) else {
            print("ExerciseImport: al geseed, overslaan.")
            return
        }

        do {
            let existing = try await exerciseRepository.countStandardExercises()
            if existing >= seedThreshold {
                print("ExerciseImport: Supabase heeft al \(existing) standaard-oefeningen, overslaan.")
                defaults.set(true, forKey: seededKey)
                return
            }

            let items = try loadSeedItems()
            print("ExerciseImport: \(items.count) oefeningen geladen uit bundle")

            guard !items.isEmpty else {
                fitnessViewModel.errorMessage = "Geen oefeningen in bundle na categorie-mapping."
                return
            }

            let batches = stride(from: 0, to: items.count, by: batchSize).map {
                Array(items[$0..<min($0 + batchSize, items.count)])
            }

            var totalInserted = 0
            for (index, batch) in batches.enumerated() {
                let inserted = try await exerciseRepository.seedStandardExercises(
                    batch: batch,
                    replaceAll: index == 0
                )
                totalInserted += inserted
                print("ExerciseImport: batch \(index + 1)/\(batches.count), inserted \(inserted)")
            }

            let finalCount = try await exerciseRepository.countStandardExercises()
            guard finalCount > 0 else {
                throw ImportError.noExercisesImported
            }

            defaults.set(true, forKey: seededKey)
            print("ExerciseImport: klaar. \(finalCount) standaard-oefeningen in Supabase.")
            await fitnessViewModel.refresh()
        } catch {
            print("ExerciseImport: fout — \(error)")
            fitnessViewModel.errorMessage = importErrorMessage(for: error)
        }
    }

    /// Reset vlag als DB leeg is maar vlag wel gezet (bijv. na mislukte eerdere poging).
    private func healSeedFlagIfDatabaseEmpty() async {
        guard defaults.bool(forKey: seededKey) else { return }
        let count = (try? await exerciseRepository.countStandardExercises()) ?? 0
        if count < seedThreshold {
            defaults.removeObject(forKey: seededKey)
            print("ExerciseImport: seed-vlag gereset (DB had \(count) standaard-oefeningen).")
        }
    }

    private func loadSeedItems() throws -> [ExerciseSeedItem] {
        guard let url = Bundle.main.url(forResource: "exercises_filtered", withExtension: "json") else {
            throw ImportError.bundleFileNotFound
        }

        let data = try Data(contentsOf: url)
        let rawExercises = try JSONDecoder().decode([RawExercise].self, from: data)
        return rawExercises.compactMap { $0.toSeedItem() }
    }

    private func importErrorMessage(for error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("seed_standard_exercises") || text.contains("pgrst202") || text.contains("42883") {
            return "Oefeningen-import mislukt: RPC ontbreekt. Draai migratie 004 op Supabase."
        }
        if text.contains("exercises") && text.contains("does not exist") || text.contains("42p01") {
            return "Oefeningen-import mislukt: fitness-tabellen ontbreken. Draai migratie 003 op Supabase."
        }
        if let importError = error as? ImportError {
            return importError.localizedDescription
        }
        return "Oefeningen-import mislukt: \(error.localizedDescription)"
    }
}
