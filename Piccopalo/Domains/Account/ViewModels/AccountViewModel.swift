import Foundation
import Combine

class AccountViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var length: Int = 0
    @Published var weight: Double = 0

    private let storage = AccountStorage()

    init() {
        loadUser()
    }

    func loadUser() {
        guard let user = storage.load() else { return }
        name = user.name
        length = user.length
        weight = user.weight
    }

    func saveUser() {
        storage.save(UserModel(name: name, length: length, weight: weight))
    }
}
