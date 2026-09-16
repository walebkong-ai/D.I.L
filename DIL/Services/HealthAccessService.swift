import Foundation

#if canImport(HealthKit)
import HealthKit

@MainActor
final class HealthAccessService {
    private let store = HKHealthStore()
    private(set) var metricStatuses: [HealthMetricKind: MetricReadStatus] = [:]
    #if DEBUG
    private(set) var diagnostics: [HealthSourceDiagnostic] = []
    private(set) var diagnosticStatuses: [HealthMetricKind: MetricReadStatus] = [:]
    #endif

    private func read<T>(_ metric: HealthMetricKind, operation: () async throws -> T?) async -> T? {
        do {
            let value = try await operation()
            metricStatuses[metric] = value == nil ? .noSamplesOrPermission : .available
            return value
        } catch {
            metricStatuses[metric] = .error
            return nil
        }
    }
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
            let steps = await read(.steps) { try await quantity(.stepCount, unit: .count(), start: start, end: queryEnd, sum: true) }
            let energy = await read(.activeEnergy) { try await quantity(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: queryEnd, sum: true) }
            let rhr = await read(.restingHeartRate) { try await quantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: queryEnd, sum: false) }
            let hrv = await read(.hrv) { try await quantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: queryEnd, sum: false) }
            let sleep: SleepAggregation? = await read(.sleep) {
                guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
                let sleepStart = calendar.date(byAdding: .hour, value: -12, to: start)!
                let fullEnd = calendar.date(byAdding: .hour, value: 12, to: start)!
                let sleepEnd = min(fullEnd, now)
                let sleepSamples = try await samples(type: type, start: sleepStart, end: sleepEnd)
                let records = sleepSamples.compactMap { sample -> SleepRecord? in
                    guard let sample = sample as? HKCategorySample else { return nil }
                    return SleepRecord(start: sample.startDate, end: sample.endDate, stage: Self.sleepStage(sample.value),
                        sourceID: sample.sourceRevision.source.bundleIdentifier)
                }
                let result = SleepAggregator.aggregate(records, window: DateInterval(start: sleepStart, end: sleepEnd), windowComplete: now >= fullEnd)
                return result.minutes == nil ? nil : result
            }
            let workoutMinutes: Double? = await read(.workouts) {
                let workouts = try await samples(type: HKObjectType.workoutType(), start: start, end: queryEnd)
                    .compactMap { $0 as? HKWorkout }.filter { $0.startDate >= start && $0.startDate < queryEnd }
                return workouts.isEmpty ? nil : workouts.reduce(0) { $0 + $1.duration / 60 }
            }
            summaries.append(DailyHealthSummary(date: start, provider: .appleHealth, sourceDevice: "Apple Health",
                sleepMinutes: sleep?.minutes, sleepEfficiency: nil, bedtimeMinutes: nil, wakeMinutes: nil,
                restingHeartRate: rhr, heartRateVariability: hrv, respiratoryRate: nil, temperatureDeviation: nil,
                steps: steps, activeEnergy: energy, workoutLoad: workoutMinutes, sleepConfidence: sleep?.confidence ?? .insufficient))
        }
        #if DEBUG
        await collectDiagnostics(start: calendar.date(byAdding: .day, value: -14, to: today)!, end: now)
        #endif
        return summaries
    }
    private static func sleepStage(_ value: Int) -> SleepStage {
        switch value {
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: .unspecified
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: .core
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: .rem
        case HKCategoryValueSleepAnalysis.awake.rawValue: .awake
        case HKCategoryValueSleepAnalysis.inBed.rawValue: .inBed
        default: .unknown
        }
    }

    #if DEBUG
    // Bounded, memory-only inspection. Never written to disk, logs, or a backend.
    private func collectDiagnostics(start: Date, end: Date) async {
        diagnostics = []
        diagnosticStatuses = [:]
        for metric in HealthMetricKind.allCases {
            let type: HKSampleType?
            switch metric {
            case .sleep: type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
            case .steps: type = HKQuantityType.quantityType(forIdentifier: .stepCount)
            case .activeEnergy: type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
            case .restingHeartRate: type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)
            case .hrv: type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
            case .workouts: type = HKObjectType.workoutType()
            }
            guard let type else { diagnosticStatuses[metric] = .unsupported; continue }
            do {
                let records: [HKSample] = try await withCheckedThrowingContinuation { continuation in
                    let query = HKSampleQuery(sampleType: type,
                        predicate: HKQuery.predicateForSamples(withStart: start, end: end),
                        limit: 100, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                        if let error { continuation.resume(throwing: error) }
                        else { continuation.resume(returning: samples ?? []) }
                    }
                    store.execute(query)
                }
                let usable = records.filter {
                    if let sleep = $0 as? HKCategorySample { return [.unspecified, .core, .deep, .rem].contains(Self.sleepStage(sleep.value)) }
                    return true
                }
                diagnosticStatuses[metric] = usable.isEmpty ? .noSamplesOrPermission : .available
                for sample in usable {
                    var value = ""
                    if let quantity = sample as? HKQuantitySample {
                        switch metric {
                        case .steps: value = "\(quantity.quantity.doubleValue(for: .count())) steps"
                        case .activeEnergy: value = "\(quantity.quantity.doubleValue(for: .kilocalorie())) kcal"
                        case .restingHeartRate: value = "\(quantity.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))) bpm"
                        case .hrv: value = "\(quantity.quantity.doubleValue(for: .secondUnit(with: .milli))) ms"
                        default: break
                        }
                    } else if let sleep = sample as? HKCategorySample {
                        value = "\(Self.sleepStage(sleep.value).rawValue) · \(Int(sleep.endDate.timeIntervalSince(sleep.startDate) / 60)) min"
                    } else if let workout = sample as? HKWorkout {
                        value = "Workout type \(workout.workoutActivityType.rawValue) · \(Int(workout.duration / 60)) min"
                    }
                    diagnostics.append(HealthSourceDiagnostic(metric: metric, start: sample.startDate, end: sample.endDate,
                        sourceName: sample.sourceRevision.source.name, bundleID: sample.sourceRevision.source.bundleIdentifier,
                        version: sample.sourceRevision.version, deviceName: sample.device?.name, deviceModel: sample.device?.model,
                        value: value))
                }
            } catch { diagnosticStatuses[metric] = .error }
        }
    }
    #endif

}
#else
@MainActor
final class HealthAccessService {
    var isHealthDataAvailable: Bool { false }
    private(set) var metricStatuses: [HealthMetricKind: MetricReadStatus] = [:]
    #if DEBUG
    private(set) var diagnostics: [HealthSourceDiagnostic] = []
    private(set) var diagnosticStatuses: [HealthMetricKind: MetricReadStatus] = [:]
    #endif
    func requestCoreWellnessAccess() async throws { }
    func fetchRecentSummaries(now: Date = .now, calendar: Calendar = .current) async throws -> [DailyHealthSummary] { [] }
}
#endif
