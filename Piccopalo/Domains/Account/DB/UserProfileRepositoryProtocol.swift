import Foundation

protocol UserProfileRepositoryProtocol: AnyObject {
    func loadAccount() async -> AccountData?
    func saveAccount(_ data: AccountData) async
}