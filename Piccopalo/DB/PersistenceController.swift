import Foundation
import SwiftData
/// Centrale SwiftData-container en repositories (main actor).
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer
    let diaryRepository: DiaryRepositoryProtocol
    let userProfileRepository: UserProfileRepositoryProtocol

    private init() {
        let schema = Schema([DiaryDayEntity.self, DiaryProteinEntryEntity.self, UserProfileEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData ModelContainer failed: \(error)")
        }

        let context = container.mainContext
        diaryRepository = SwiftDataDiaryRepository(modelContext: context)
        userProfileRepository = SwiftDataUserProfileRepository(modelContext: context)

        SwiftDataMigration.runIfNeeded(modelContext: context)
    }

    /// In-memory container + repositories voor previews en tests.
    static func makePreview() -> (ModelContainer, DiaryRepositoryProtocol, UserProfileRepositoryProtocol) {
        let schema = Schema([DiaryDayEntity.self, DiaryProteinEntryEntity.self, UserProfileEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let diary = SwiftDataDiaryRepository(modelContext: context)
        let user = SwiftDataUserProfileRepository(modelContext: context)
        return (container, diary, user)
    }

    /// Container + view models for SwiftUI previews (in-memory store).
    @MainActor
    static func previewStack() -> (ModelContainer, ProteinViewModel, AccountViewModel) {
        let (container, diary, user) = makePreview()
        let protein = ProteinViewModel(diaryRepository: diary, userProfileRepository: user)
        let account = AccountViewModel(userProfileRepository: user)
        return (container, protein, account)
    }
}
