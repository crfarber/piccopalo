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
                }
        }
    }
    
    private func initializeNotifications() {
        NotificationService.shared.requestPermissions { granted in
            if granted {
                NotificationService.shared.setupBackgroundStepMonitoring()
                NotificationService.shared.scheduleDailyReminder(stepsGoal: 8000, healthManager: healthManager)
            }
        }
    }
}