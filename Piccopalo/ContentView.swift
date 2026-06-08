import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var fitnessViewModel: FitnessViewModel

    var body: some View {
        if authViewModel.isAuthenticated {
            NavigationStack {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Vandaag", systemImage: "house.fill")
                        }

                    FitnessHomeView()
                        .tabItem {
                            Label("Training", systemImage: "dumbbell.fill")
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
            .task(id: authViewModel.isAuthenticated) {
                guard authViewModel.isAuthenticated else { return }
                await ExerciseImportService(
                    exerciseRepository: SupabaseExerciseRepository(),
                    fitnessViewModel: fitnessViewModel
                ).seedIfNeeded()
            }
        } else {
            LoginView()
        }
    }
}

