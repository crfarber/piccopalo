import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isAuthenticated {
            NavigationStack {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Vandaag", systemImage: "house.fill")
                        }

                    HistoryView()
                        .tabItem {
                            Label("Historie", systemImage: "calendar")
                        }
                }
                .tint(.green)
                .toolbarBackground(DesignTokens.Colors.background, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
            }
        } else {
            LoginView()
        }
    }
}

