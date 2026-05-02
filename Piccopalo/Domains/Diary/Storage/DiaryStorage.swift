import Foundation

class DiaryStorage {
    private let key = "diary"

    func save(_ entries:  DayRecord) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> [DayRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([DayRecord].self, from: data)
        else { return [] }
        return entries
    }
}