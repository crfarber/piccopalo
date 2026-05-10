import Foundation
import Combine

extension Notification.Name {
    static let piccopaloAccountDidChange = Notification.Name("piccopaloAccountDidChange")
}

@MainActor
class AccountViewModel: ObservableObject {
    @Published var name: String = "User"
    @Published var weight: String = ""
    @Published var height: String = ""
    @Published var activityFactor: Double = 1.2

    private let userProfileRepository: UserProfileRepositoryProtocol

    let activityOptions: [(label: String, factor: Double)] = [
        ("Weinig beweging", 0.8),
        ("Licht actief", 1.2),
        ("Regelmatig sporten", 1.4),
        ("Intensief trainen", 1.6)
    ]

    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository
        loadAccount()
    }

    func loadAccount() {
        Task {
            if let decoded = await userProfileRepository.loadAccount() {
                apply(decoded)
                return
            }

            if let legacy = AccountStorage().load() {
                name = legacy.name.isEmpty ? "User" : legacy.name
                weight = legacy.weight > 0 ? String(legacy.weight) : ""
                height = legacy.length > 0 ? String(legacy.length) : ""
                activityFactor = 1.2
                saveAccount()
            }
        }
    }

    func saveAccount() {
        let data = AccountData(
            name: name,
            weight: Double(weight) ?? 0,
            height: Double(height) ?? 0,
            activityFactor: activityFactor
        )
        Task {
            await userProfileRepository.saveAccount(data)
            NotificationCenter.default.post(name: .piccopaloAccountDidChange, object: nil)
        }
    }

    private func apply(_ decoded: AccountData) {
        name = decoded.name.isEmpty ? "User" : decoded.name
        weight = decoded.weight > 0 ? String(decoded.weight) : ""
        height = decoded.height > 0 ? String(decoded.height) : ""
        activityFactor = decoded.activityFactor
    }

    var dailyProteinGoal: Double {
        (Double(weight) ?? 0) * activityFactor
    }
}

struct AccountData: Codable {
    let name: String
    let weight: Double
    let height: Double
    let activityFactor: Double
}
