import SwiftUI
import SwiftData

@main
struct PiccopaloApp: App {
    private let persistence = PersistenceController.shared

    @StateObject private var proteinViewModel: ProteinViewModel
    @StateObject private var accountViewModel: AccountViewModel
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        let diary = persistence.diaryRepository
        let user = persistence.userProfileRepository
        _proteinViewModel = StateObject(wrappedValue: ProteinViewModel(
            diaryRepository: diary,
            userProfileRepository: user
        ))
        _accountViewModel = StateObject(wrappedValue: AccountViewModel(
            userProfileRepository: user
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proteinViewModel)
                .environmentObject(accountViewModel)
                .environmentObject(authViewModel)
        }
        .modelContainer(persistence.container)
    }
}
