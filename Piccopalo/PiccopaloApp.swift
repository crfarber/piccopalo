import SwiftUI

@main
struct PiccopaloApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var proteinViewModel = ProteinViewModel(
        diaryRepository: SupabaseDiaryRepository(),
        userProfileRepository: SupabaseUserProfileRepository()
    )

    @StateObject private var accountViewModel = AccountViewModel(
        userProfileRepository: SupabaseUserProfileRepository()
    )

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var healthManager = HealthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proteinViewModel)
                .environmentObject(accountViewModel)
                .environmentObject(authViewModel)
                .environmentObject(healthManager)
                .onAppear {
                    initializeNotifications()
                    healthManager.startBackgroundStepMonitoringIfAuthorized()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        NotificationService.shared.scheduleBackgroundRefreshNow()
                    }
                }
                .onChange(of: healthManager.lastUpdated) { _, _ in
                    let newFactor = healthManager.calculateActivityFactor()
                    if accountViewModel.activityFactor != newFactor {
                        accountViewModel.activityFactor = newFactor
                        accountViewModel.saveAccount()
                    }
                }
        }
    }
    
    private func initializeNotifications() {
        NotificationService.shared.requestPermissions { granted in
            if granted {
                NotificationService.shared.setupBackgroundStepMonitoring()
                NotificationService.shared.scheduleDailyReminder(stepsGoal: 10000, healthManager: healthManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProteinViewModel(
            diaryRepository: SupabaseDiaryRepository(),
            userProfileRepository: SupabaseUserProfileRepository()
        ))
        .environmentObject(AccountViewModel(
            userProfileRepository: SupabaseUserProfileRepository()
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(HealthManager())
}

