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

                    DayTimelineView()
                        .tabItem {
                            Label("Dag", systemImage: "list.bullet.rectangle")
                        }

                    WeeklyInsightsView()
                        .tabItem {
                            Label("Inzichten", systemImage: "chart.line.uptrend.xyaxis")
                        }
                }
                .tint(.green)
                .toolbarBackground(Theme.Colors.background, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
            }
        } else {
            LoginView()
        }
    }
}

