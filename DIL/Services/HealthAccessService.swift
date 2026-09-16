import Foundation

#if canImport(HealthKit)
import HealthKit

@MainActor
final class HealthAccessService {
    private let store = HKHealthStore()
    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestCoreWellnessAccess() async throws {
        let identifiers: [HKQuantityTypeIdentifier] = [.stepCount, .activeEnergyBurned, .restingHeartRate, .heartRateVariabilitySDNN]
        var types = Set<HKObjectType>(identifiers.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
        types.insert(HKObjectType.workoutType())
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        try await store.requestAuthorization(toShare: [], read: types)
    }

    private func samples(type: HKSampleType, start: Date, end: Date) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples ?? []) }
            }
            store.execute(query)
        }
    }

    private func quantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date, sum: Bool) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: sum ? .cumulativeSum : .discreteAverage) { _, statistics, error in
                if let error { continuation.resume(throwing: error); return }
                let value = sum ? statistics?.sumQuantity() : statistics?.averageQuantity()
                continuation.resume(returning: value?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    func fetchRecentSummaries(now: Date = .now, calendar: Calendar = .current) async throws -> [DailyHealthSummary] {
        guard isHealthDataAvailable else { return [] }
        var summaries: [DailyHealthSummary] = []
        let today = calendar.startOfDay(for: now)
        for offset in (-14)...0 {
            guard let start = calendar.date(byAdding: .day, value: offset, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            let queryEnd = min(end, now)
            let steps = try await quantity(.stepCount, unit: .count(), start: start, end: queryEnd, sum: true)
            let energy = try await quantity(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: queryEnd, sum: true)
            let rhr = try await quantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: queryEnd, sum: false)
            let hrv = try await quantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: queryEnd, sum: false)
            var sleepMinutes: Double?
            if let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
                // Attribute overnight sleep to wake date, and union overlapping sources/stages.
                let sleepStart = calendar.date(byAdding: .hour, value: -12, to: start)!
                let sleepEnd = min(calendar.date(byAdding: .hour, value: 12, to: start)!, now)
                let sleepSamples = try await samples(type: type, start: sleepStart, end: sleepEnd)
                let intervals = sleepSamples.compactMap { sample -> DateInterval? in
                    guard let sample = sample as? HKCategorySample,
                          [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepDeep.rawValue, HKCategoryValueSleepAnalysis.asleepREM.rawValue].contains(sample.value) else { return nil }
                    let lower = max(sleepStart, sample.startDate), upper = min(sleepEnd, sample.endDate)
                    return upper > lower ? DateInterval(start: lower, end: upper) : nil
                }.sorted { $0.start < $1.start }
                var merged: [DateInterval] = []
                for interval in intervals {
                    if let last = merged.last, interval.start <= last.end {
                        merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
                    } else { merged.append(interval) }
                }
                if !merged.isEmpty { sleepMinutes = merged.reduce(0) { $0 + $1.duration / 60 } }
            }
            let workouts = try await samples(type: HKObjectType.workoutType(), start: start, end: queryEnd).compactMap { $0 as? HKWorkout }.filter { $0.startDate >= start && $0.startDate < queryEnd }
            summaries.append(DailyHealthSummary(date: start, provider: .appleHealth, sourceDevice: "Apple Health",
                sleepMinutes: sleepMinutes, sleepEfficiency: nil, bedtimeMinutes: nil, wakeMinutes: nil,
                restingHeartRate: rhr, heartRateVariability: hrv, respiratoryRate: nil, temperatureDeviation: nil,
                steps: steps, activeEnergy: energy, workoutLoad: workouts.isEmpty ? nil : workouts.reduce(0) { $0 + $1.duration / 60 }))
        }
        return summaries
    }
}
#else
@MainActor
final class HealthAccessService {
    var isHealthDataAvailable: Bool { false }
    func requestCoreWellnessAccess() async throws { }
    func fetchRecentSummaries(now: Date = .now, calendar: Calendar = .current) async throws -> [DailyHealthSummary] { [] }
}
#endif
