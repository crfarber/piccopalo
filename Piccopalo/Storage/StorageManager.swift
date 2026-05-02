import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let key = "piccopalo_records"

    private init() {}

    func saveRecord(for date: String, record: DayRecord) {
        var records = loadAllRecordsDict()
        records[date] = record
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func loadRecord(for date: String) -> DayRecord? {
        loadAllRecordsDict()[date]
    }

    func loadAllRecords() -> [DayRecord] {
        loadAllRecordsDict().values.sorted { $0.date > $1.date }
    }

    private func loadAllRecordsDict() -> [String: DayRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([String: DayRecord].self, from: data)
        else { return [:] }
        return records
    }
}
