import Foundation

protocol UserProfileRepositoryProtocol: AnyObject {
    func loadAccount() -> AccountData?
    func saveAccount(_ data: AccountData)
}
