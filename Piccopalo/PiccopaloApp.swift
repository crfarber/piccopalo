import SwiftUI

@main
struct PiccopaloApp: App {
    @StateObject private var proteinViewModel = ProteinViewModel(
        diaryRepository: SupabaseDiaryRepository(),
        userProfileRepository: SupabaseUserProfileRepository()
    )

    @StateObject private var accountViewModel = AccountViewModel(
        userProfileRepository: SupabaseUserProfileRepository()
    )

    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proteinViewModel)
                .environmentObject(accountViewModel)
                .environmentObject(authViewModel)
        }
    }
}