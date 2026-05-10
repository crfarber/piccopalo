import Foundation
import SwiftData

enum PiccopaloPersistenceKeys {
    static let records = "piccopalo_records"
    static let account = "piccopalo_account"
    static let migrationFlag = "swiftDataMigrated_v1"
}

enum SwiftDataMigration {
    /// Importeert bestaande UserDefaults-data één keer naar SwiftData.
    @MainActor
    static func runIfNeeded(modelContext: ModelContext) {
        if UserDefaults.standard.bool(forKey: PiccopaloPersistenceKeys.migrationFlag) {
            return
        }

        let diaryCount = (try? modelContext.fetch(FetchDescriptor<DiaryDayEntity>()))?.count ?? 0
        let userCount = (try? modelContext.fetch(FetchDescriptor<UserProfileEntity>()))?.count ?? 0
        if diaryCount > 0 || userCount > 0 {
            UserDefaults.standard.set(true, forKey: PiccopaloPersistenceKeys.migrationFlag)
            return
        }

        if let data = UserDefaults.standard.data(forKey: PiccopaloPersistenceKeys.records),
           let dict = try? JSONDecoder().decode([String: DayRecord].self, from: data) {
            for (_, record) in dict {
                modelContext.insert(DiaryDayEntity(from: record))
            }
        }

        if let data = UserDefaults.standard.data(forKey: PiccopaloPersistenceKeys.account),
           let account = try? JSONDecoder().decode(AccountData.self, from: data) {
            modelContext.insert(UserProfileEntity(from: account))
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: PiccopaloPersistenceKeys.migrationFlag)
    }
}
