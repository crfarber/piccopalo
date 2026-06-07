import UserNotifications
import UIKit
import Foundation

@MainActor
class WaterNotificationScheduler {
    private let userDefaults = UserDefaults.standard
    private let waterThresholdKeyPrefix = "piccopalo_water_threshold_"
    private let waterGoalReachedKeyPrefix = "piccopalo_water_goal_reached_"

    // MARK: - Public API

    /// Schedule daily water notifications based on current water intake
    func scheduleDaily(currentWaterMl: Int, goalMl: Int) async {
        // Remove existing water notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "piccopalo.water.11",
                "piccopalo.water.14",
                "piccopalo.water.17",
                "piccopalo.water.20",
                "piccopalo.water.goal"
            ]
        )

        // Schedule threshold notifications
        let thresholds: [(hour: Int, minute: Int, percent: Double, messageKey: String)] = [
            (11, 0, 0.20, "11"),
            (14, 0, 0.45, "14"),
            (17, 0, 0.65, "17"),
            (20, 0, 0.85, "20")
        ]

        for (hour, minute, minPercent, key) in thresholds {
            let currentPercent = goalMl > 0 ? Double(currentWaterMl) / Double(goalMl) : 0
            
            // Only schedule if current progress is below threshold
            if currentPercent < minPercent && !hasThresholdFiredToday(key) {
                scheduleThresholdNotification(hour: hour, minute: minute, key: key)
            }
        }

        // Schedule "goal reached" notification check
        let currentPercent = goalMl > 0 ? Double(currentWaterMl) / Double(goalMl) : 0
        if currentPercent >= 1.0 && !hasGoalReachedFiredToday() {
            markGoalReachedFired()
            sendGoalReachedNotification()
        }
    }

    /// Mark that goal has been reached today (one-time notification)
    func checkGoalReached(currentWaterMl: Int, goalMl: Int) {
        let currentPercent = goalMl > 0 ? Double(currentWaterMl) / Double(goalMl) : 0
        if currentPercent >= 1.0 && !hasGoalReachedFiredToday() {
            markGoalReachedFired()
            sendGoalReachedNotification()
        }
    }

    // MARK: - Private Helpers

    private func scheduleThresholdNotification(hour: Int, minute: Int, key: String) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Water intake reminder"
        content.body = messageForThreshold(key)
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "piccopalo.water.\(key)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule water notification at \(hour):\(minute): \(error.localizedDescription)")
            }
        }
    }

    private func sendGoalReachedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Water goal reached! 💧"
        content.body = "Dagdoel water gehaald! Goed bezig."
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "piccopalo.water.goal.immediate", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send goal reached notification: \(error.localizedDescription)")
            }
        }
    }

    private func messageForThreshold(_ key: String) -> String {
        switch key {
        case "11":
            return "Je bent nog niet goed op weg. Pak een groot glas water! 💧"
        case "14":
            return "Halverwege de dag — heb je al genoeg gedronken?"
        case "17":
            return "Nog een paar uur. Een glas water nu helpt je de finish te halen."
        case "20":
            return "Bijna de avond in — hoe staat het met je water vandaag?"
        default:
            return "Drink wat water! 💧"
        }
    }

    private func hasThresholdFiredToday(_ key: String) -> Bool {
        let today = dateKeyForToday()
        let storageKey = waterThresholdKeyPrefix + today + "_" + key
        return userDefaults.bool(forKey: storageKey)
    }

    private func markThresholdFired(_ key: String) {
        let today = dateKeyForToday()
        let storageKey = waterThresholdKeyPrefix + today + "_" + key
        userDefaults.set(true, forKey: storageKey)
    }

    private func hasGoalReachedFiredToday() -> Bool {
        let today = dateKeyForToday()
        let storageKey = waterGoalReachedKeyPrefix + today
        return userDefaults.bool(forKey: storageKey)
    }

    private func markGoalReachedFired() {
        let today = dateKeyForToday()
        let storageKey = waterGoalReachedKeyPrefix + today
        userDefaults.set(true, forKey: storageKey)
    }

    private func dateKeyForToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
