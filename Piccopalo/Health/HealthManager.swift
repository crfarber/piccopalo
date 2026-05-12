import HealthKit
import Foundation
import Combine

@MainActor
class HealthManager: NSObject, ObservableObject {
    @Published var steps: Int = 0
    @Published var activeEnergy: Double = 0
    @Published var exerciseTime: Int = 0
    @Published var distance: Double = 0
    @Published var flightsClimbed: Int = 0
    @Published var weeklyAverageSteps: Int = 0
    @Published var weeklyAverageActiveEnergy: Double = 0
    @Published var weeklyAverageExerciseTime: Int = 0
    @Published var isAuthorized: Bool = false
    @Published var canRequestAuthorization: Bool = true
    @Published var diagnostics: String? = nil
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: Date? = nil
    
    private let healthStore = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    private var hasConfiguredObservers = false
    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.flightsClimbed)
        ]
    }
    
    override init() {
        super.init()
        checkHealthKitAvailability()
    }
    
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }

        refreshAuthorizationStatus()
    }
    
    func requestAuthorization() async {
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            refreshAuthorizationStatus()
            await fetchTodayData()
            startBackgroundStepMonitoringIfAuthorized()
        } catch {
            errorMessage = "Authorization request failed: \(error.localizedDescription)"
        }
    }

    /// Starts HealthKit observers/background delivery if permission is already granted.
    /// Call this at app launch so monitoring works without visiting HealthView first.
    func startBackgroundStepMonitoringIfAuthorized() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let status = healthStore.authorizationStatus(for: stepType)
        guard status == .sharingAuthorized else { return }

        isAuthorized = true

        if !hasConfiguredObservers {
            setupHealthKitObservers()
            hasConfiguredObservers = true
        }

        Task {
            await fetchTodayData()
        }
    }

    func refreshAuthorizationStatus() {
        healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes) { [weak self] status, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.errorMessage = "Health status check failed: \(error.localizedDescription)"
                    return
                }

                switch status {
                case .shouldRequest:
                    self.canRequestAuthorization = true
                    if !self.isAuthorized {
                        self.errorMessage = nil
                    }
                case .unnecessary:
                    self.canRequestAuthorization = false
                    self.isAuthorized = true
                case .unknown:
                    self.canRequestAuthorization = true
                @unknown default:
                    self.canRequestAuthorization = true
                }
            }
        }
    }
    
    func fetchTodayData() async {
        refreshAuthorizationStatus()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = Date()
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: startOfDay) ?? startOfDay
        let weekPredicate = HKQuery.predicateForSamples(withStart: weekStart, end: endOfDay)
        let daysInWindow = 7.0

        async let fetchedSteps = safeCumulativeSum(
                label: "steps",
                for: .stepCount,
                unit: HKUnit.count(),
                predicate: todayPredicate
            )
        async let fetchedActiveEnergy = safeCumulativeSum(
                label: "activeEnergy",
                for: .activeEnergyBurned,
                unit: HKUnit.kilocalorie(),
                predicate: todayPredicate
            )
        async let fetchedExerciseTime = safeCumulativeSum(
                label: "exerciseTime",
                for: .appleExerciseTime,
                unit: HKUnit.minute(),
                predicate: todayPredicate
            )
        async let fetchedDistance = safeCumulativeSum(
                label: "distance",
                for: .distanceWalkingRunning,
                unit: HKUnit.meterUnit(with: .kilo),
                predicate: todayPredicate
            )
        async let fetchedFlights = safeCumulativeSum(
                label: "flights",
                for: .flightsClimbed,
                unit: HKUnit.count(),
                predicate: todayPredicate
            )
        async let weeklyStepsTotal = safeCumulativeSum(
                label: "weeklySteps",
                for: .stepCount,
                unit: HKUnit.count(),
                predicate: weekPredicate
            )
        async let weeklyEnergyTotal = safeCumulativeSum(
                label: "weeklyEnergy",
                for: .activeEnergyBurned,
                unit: HKUnit.kilocalorie(),
                predicate: weekPredicate
            )
        async let weeklyExerciseTotal = safeCumulativeSum(
                label: "weeklyExercise",
                for: .appleExerciseTime,
                unit: HKUnit.minute(),
                predicate: weekPredicate
            )

        let (
            stepsResult,
            energyResult,
            exerciseResult,
            distanceResult,
            flightsResult,
            weeklyStepsResult,
            weeklyEnergyResult,
            weeklyExerciseResult
        ) = await (
            fetchedSteps,
            fetchedActiveEnergy,
            fetchedExerciseTime,
            fetchedDistance,
            fetchedFlights,
            weeklyStepsTotal,
            weeklyEnergyTotal,
            weeklyExerciseTotal
        )

        steps = Int(stepsResult.value)
        activeEnergy = energyResult.value
        exerciseTime = Int(exerciseResult.value)
        distance = distanceResult.value
        flightsClimbed = Int(flightsResult.value)
        weeklyAverageSteps = Int(weeklyStepsResult.value / daysInWindow)
        weeklyAverageActiveEnergy = weeklyEnergyResult.value / daysInWindow
        weeklyAverageExerciseTime = Int(weeklyExerciseResult.value / daysInWindow)

        let queryErrors = [
            stepsResult.error,
            energyResult.error,
            exerciseResult.error,
            distanceResult.error,
            flightsResult.error,
            weeklyStepsResult.error,
            weeklyEnergyResult.error,
            weeklyExerciseResult.error
        ].compactMap { $0 }

        diagnostics = queryErrors.isEmpty ? nil : queryErrors.joined(separator: " | ")

        let noTodayData = steps == 0 && activeEnergy == 0 && exerciseTime == 0 && distance == 0 && flightsClimbed == 0
        let noWeeklyData = weeklyAverageSteps == 0 && weeklyAverageActiveEnergy == 0 && weeklyAverageExerciseTime == 0

        if noTodayData && noWeeklyData {
            errorMessage = "Geen Health-data ontvangen. Controleer toegang in de Health-app: Profiel > Apps > Piccopalo."
        } else {
            errorMessage = nil
        }

        lastUpdated = Date()
    }

    private func safeCumulativeSum(
        label: String,
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate
    ) async -> (value: Double, error: String?) {
        do {
            let value = try await cumulativeSum(for: identifier, unit: unit, predicate: predicate)
            return (value, nil)
        } catch {
            return (0, "\(label)=\(error.localizedDescription)")
        }
    }

    private func cumulativeSum(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw NSError(
                domain: "HealthManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unsupported HealthKit type: \(identifier.rawValue)"]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    /// Calculates activity factor using a 7-day weighted model.
    /// Week average drives the baseline while today's data fine-tunes the result.
    func calculateActivityFactor() -> Double {
        let todayScore = activityScore(
            steps: Double(steps),
            activeEnergy: activeEnergy,
            exerciseMinutes: Double(exerciseTime)
        )
        let baselineScore = activityScore(
            steps: Double(weeklyAverageSteps),
            activeEnergy: weeklyAverageActiveEnergy,
            exerciseMinutes: Double(weeklyAverageExerciseTime)
        )

        let combinedScore = (baselineScore * 0.7) + (todayScore * 0.3)

        if combinedScore < 0.25 {
            return 0.8 // Weinig beweging
        } else if combinedScore < 0.5 {
            return 1.2 // Licht actief
        } else if combinedScore < 0.75 {
            return 1.4 // Regelmatig sporten
        } else {
            return 1.6 // Intensief trainen
        }
    }

    private func activityScore(steps: Double, activeEnergy: Double, exerciseMinutes: Double) -> Double {
        let stepsScore = min(steps / 10_000, 1.0)
        let activeEnergyScore = min(activeEnergy / 500, 1.0)
        let exerciseScore = min(exerciseMinutes / 45, 1.0)
        return (activeEnergyScore * 0.5) + (exerciseScore * 0.3) + (stepsScore * 0.2)
    }
    
    func getActivityLevel() -> String {
        let factor = calculateActivityFactor()
        switch factor {
        case 0.8:
            return "Weinig beweging"
        case 1.2:
            return "Licht actief"
        case 1.4:
            return "Regelmatig sporten"
        case 1.6:
            return "Intensief trainen"
        default:
            return "Onbekend"
        }
    }
    
    /// Fetches today's step count with a callback
    /// Used by NotificationService for background notifications
    func getTodaySteps(completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = Date()
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        
        Task {
            let stepsResult = await safeCumulativeSum(
                label: "steps",
                for: .stepCount,
                unit: HKUnit.count(),
                predicate: todayPredicate
            )
            completion(stepsResult.value)
        }
    }
    
    /// Setup real-time observers for HealthKit data changes
    /// Automatically refetches data when Health app updates
    private func setupHealthKitObservers() {
        // Observer voor stappen
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if let error {
                print("Enable background delivery failed: \(error.localizedDescription)")
            } else if !success {
                print("Enable background delivery returned false for steps")
            }
        }
        
        let stepsObserver = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("Steps observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Refetch data wanneer stappen update
            Task { @MainActor in
                await self?.fetchTodayData()

                // Trigger notification check voor drempels
                if let self = self {
                    self.getTodaySteps { steps in
                        Task { @MainActor in
                            NotificationService.shared.checkThresholdNotifications(stepsCount: Int(steps), stepsGoal: 10000)
                        }
                    }
                }
                completionHandler()
            }
        }
        
        healthStore.execute(stepsObserver)
        observerQueries.append(stepsObserver)
    }
}
