import UserNotifications
import BackgroundTasks
import HealthKit
import UIKit
import Foundation

@MainActor
class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let healthStore = HKHealthStore()
    private var stepsGoal: Int = 10000
    private let userDefaults = UserDefaults.standard
    private let bgTaskIdentifier = "com.piccopalo.stepcheck"
    private var isBackgroundTaskRegistered = false
    
    // Keys for UserDefaults threshold tracking
    private let thresholdKeyPrefix = "piccopalo_thresholds_"
    private let stepsGoalKey = "piccopalo_stepsGoal"
    
    override init() {
        super.init()
        loadStepsGoal()
    }
    
    // MARK: - Public API
    
    /// Request notification permissions from user
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    /// Schedule daily reminder at 13:00
    func scheduleDailyReminder(stepsGoal: Int, healthManager: HealthManager) {
        self.stepsGoal = stepsGoal
        userDefaults.set(stepsGoal, forKey: stepsGoalKey)
        
        // Remove existing reminder first
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder13:00"])
        
        // Fetch today's steps now and schedule based on that
        healthManager.getTodaySteps { [weak self] steps in
            DispatchQueue.main.async {
                self?.scheduleReminderAtThirteen(stepsCount: Int(steps), stepsGoal: stepsGoal)
            }
        }
    }
    
    /// Setup background step monitoring
    func setupBackgroundStepMonitoring() {
        // Register background task handler
        if !isBackgroundTaskRegistered {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskIdentifier, using: nil) { [weak self] task in
                self?.handleBackgroundStepCheck(task: task as! BGAppRefreshTask)
            }
            isBackgroundTaskRegistered = true
        }
        
        // Schedule first background task
        scheduleNextBackgroundRefresh()
    }

    /// Re-schedules periodic background step checks when app goes to background.
    func scheduleBackgroundRefreshNow() {
        scheduleNextBackgroundRefresh()
    }
    
    /// Check and fire threshold notifications (can be called from HealthManager on real-time updates)
    func checkThresholdNotifications(stepsCount: Int, stepsGoal: Int) {
        checkAndFireThresholdNotifications(stepsCount: stepsCount, stepsGoal: stepsGoal)
    }
    
    // MARK: - Private Helpers
    
    private func scheduleReminderAtThirteen(stepsCount: Int, stepsGoal: Int) {
        let percentage = Double(stepsCount) / Double(stepsGoal) * 100
        
        guard let message = messageForStepPercentage(percentage) else {
            // No notification needed (≥ 60%)
            return
        }
        
        // Schedule notification for 13:00 daily
        var dateComponents = DateComponents()
        dateComponents.hour = 13
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Stappen vandaag"
        content.body = message
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder13:00", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleBackgroundStepCheck(task: BGAppRefreshTask) {
        // For background tasks, we need to read steps without HealthManager context
        // Use direct HealthKit query
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = Date()
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            task.setTaskCompleted(success: false)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: quantityType,
            quantitySamplePredicate: todayPredicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Background step query error: \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                self?.checkAndFireThresholdNotifications(stepsCount: Int(steps), stepsGoal: self?.stepsGoal ?? 10000)
                task.setTaskCompleted(success: true)
            }
        }
        healthStore.execute(query)
        
        // Schedule next refresh
        scheduleNextBackgroundRefresh()
    }
    
    private func checkAndFireThresholdNotifications(stepsCount: Int, stepsGoal: Int) {
        let thresholds = [80, 95, 100]
        let percentage = Double(stepsCount) / Double(stepsGoal) * 100
        
        for threshold in thresholds {
            let thresholdPercent = Double(threshold)
            if percentage >= thresholdPercent && !hasThresholdFiredToday(threshold) {
                markThresholdFired(threshold)
                
                let message: String
                switch threshold {
                case 80:
                    message = "Bijna daar! Nog een klein stukje en je haalt je doel."
                case 95:
                    message = "Nog een paar stappen en je bent er. Ga ervoor! 🎯"
                case 100:
                    message = "Dagdoel gehaald! Zo doe je dat. 💪"
                default:
                    message = "Goed bezig met je stappendoel!"
                }
                
                sendNotification(
                    title: "Stappendoel: \(threshold)%",
                    body: message,
                    badge: NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
                )
            }
        }
    }
    
    private func messageForStepPercentage(_ percentage: Double) -> String? {
        if percentage < 30 {
            return "Je hebt nog de hele middag. Even een blokje om?"
        } else if percentage >= 40 && percentage <= 60 {
            return "Goed bezig! Nog even doorzetten voor je dagdoel."
        } else if percentage > 60 {
            return nil  // Don't send notification
        }
        return nil
    }
    
    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: bgTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15)  // ~15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error.localizedDescription)")
        }
    }
    
    private func hasThresholdFiredToday(_ threshold: Int) -> Bool {
        let today = dateKeyForToday()
        let key = thresholdKeyPrefix + today
        
        if let firedThresholds = userDefaults.array(forKey: key) as? [Int] {
            return firedThresholds.contains(threshold)
        }
        return false
    }
    
    private func markThresholdFired(_ threshold: Int) {
        let today = dateKeyForToday()
        let key = thresholdKeyPrefix + today
        
        var firedThresholds = userDefaults.array(forKey: key) as? [Int] ?? []
        if !firedThresholds.contains(threshold) {
            firedThresholds.append(threshold)
            userDefaults.set(firedThresholds, forKey: key)
        }
    }
    
    private func dateKeyForToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func sendNotification(title: String, body: String, badge: NSNumber) {
        NotificationStore.shared.add(title: title, body: body)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = badge
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadStepsGoal() {
        stepsGoal = userDefaults.integer(forKey: stepsGoalKey)
        if stepsGoal == 0 {
            stepsGoal = 10000
        }
    }
}
