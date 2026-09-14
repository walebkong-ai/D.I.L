import Foundation

#if canImport(HealthKit)
import HealthKit

final class HealthAccessService {
    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestCoreWellnessAccess() async throws {
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let walkingRunningDistance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)
        let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass)
        let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        let workouts = HKObjectType.workoutType()

        let readTypes = Set([
            stepCount,
            walkingRunningDistance,
            activeEnergy,
            heartRate,
            bodyMass,
            sleep,
            workouts
        ].compactMap { $0 })

        try await store.requestAuthorization(toShare: [], read: readTypes)
    }
}
#else
final class HealthAccessService {
    var isHealthDataAvailable: Bool { false }

    func requestCoreWellnessAccess() async throws { }
}
#endif
