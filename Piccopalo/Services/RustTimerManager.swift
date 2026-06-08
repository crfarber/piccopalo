import Foundation
import Combine
import AudioToolbox
import UserNotifications

/// Eenvoudige rust-timer met countdown, achtergrond-notificatie en trilsignaal.
@MainActor
final class RustTimerManager: ObservableObject {
    @Published var secondsRemaining: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isRunning: Bool = false

    private var timer: Timer?
    private static let notificationId = "rustTimer"

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - secondsRemaining) / Double(totalSeconds)
    }

    func start(seconds: Int) {
        guard seconds > 0 else { return }
        stop()
        totalSeconds = seconds
        secondsRemaining = seconds
        isRunning = true
        scheduleNotification(after: seconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.secondsRemaining > 1 {
                    self.secondsRemaining -= 1
                } else {
                    self.secondsRemaining = 0
                    self.triggerCompletion()
                    self.stop()
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationId])
    }

    private func scheduleNotification(after seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rust klaar!"
        content.body = "Tijd voor je volgende set."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: Self.notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func triggerCompletion() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
