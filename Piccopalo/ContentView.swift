import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isAuthenticated {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Today", systemImage: "house.fill")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calendar")
                    }
                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person.fill")
                    }
            }
            .tint(.green)
            .toolbarBackground(DesignTokens.Colors.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
        } else {
            LoginView()
        }
    }
}

