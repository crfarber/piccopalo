import Foundation

class UserProfileRepositoryMock: UserProfileRepositoryProtocol {
    func loadAccount() async -> AccountData? {
        return AccountData(name: "Test User", weight: 75, height: 180, activityFactor: 1.2, waterGoalMl: 2000)
    }
    
    func saveAccount(_ data: AccountData) async {
        // Mock implementation
    }
}
