import Foundation
import SwiftData

@MainActor
final class SwiftDataUserProfileRepository: UserProfileRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadAccount() -> AccountData? {
        var descriptor = FetchDescriptor<UserProfileEntity>()
        descriptor.fetchLimit = 1
        guard let entity = try? modelContext.fetch(descriptor).first else { return nil }
        return entity.asAccountData
    }

    func saveAccount(_ data: AccountData) {
        var descriptor = FetchDescriptor<UserProfileEntity>()
        descriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.apply(from: data)
        } else {
            modelContext.insert(UserProfileEntity(from: data))
        }
        try? modelContext.save()
    }
}
