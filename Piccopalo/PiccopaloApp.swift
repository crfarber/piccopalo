import SwiftUI

@main
struct PiccopaloApp: App {
    @StateObject private var proteinViewModel = ProteinViewModel()
    @StateObject private var accountViewModel = AccountViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proteinViewModel)
                .environmentObject(accountViewModel)
        }
    }
}

