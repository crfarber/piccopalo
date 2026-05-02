import Foundation

class AccountStorage {
    private let key = "account"

    func save(_ user: UserModel) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> UserModel? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let user = try? JSONDecoder().decode(UserModel.self, from: data)
        else { return nil }
        return user
    }
}
