import Foundation

enum HealthProcessingChecks {
    static func run(_ check: (Bool, String) -> Void) {
        let origin = Date(timeIntervalSince1970: 1_700_000_000)
        func time(_ minutes: Double) -> Date { origin.addingTimeInterval(minutes * 60) }
        let window = DateInterval(start: time(0), end: time(600))
        func record(_ start: Double, _ end: Double, _ stage: SleepStage, _ source: String = "sourceA") -> SleepRecord {
            SleepRecord(start: time(start), end: time(end), stage: stage, sourceID: source)
        }
        func aggregate(_ records: [SleepRecord], complete: Bool = true) -> SleepAggregation {
            SleepAggregator.aggregate(records, window: window, windowComplete: complete)
        }
        check(aggregate([record(60, 120, .unspecified)]).minutes == 60, "single sleep interval")
        check(aggregate([record(60, 120, .core), record(120, 180, .rem), record(180, 240, .deep)]).minutes == 180, "multiple sleep stages")
        check(aggregate([record(60, 180, .unspecified), record(120, 240, .deep)]).minutes == 180, "overlapping records union")
        check(aggregate([record(60, 240, .unspecified), record(120, 150, .awake), record(130, 160, .awake)]).minutes == 140, "awake intervals excluded once")
        check(aggregate([record(60, 240, .inBed)]).minutes == nil, "in-bed only no sleep inferred")
        check(aggregate([record(60, 240, .unspecified)]).minutes == 180, "generic asleep without stages gives duration only")
        check(aggregate([record(60, 120, .core)], complete: false).confidence == .partial, "partial night provisional")
        check(aggregate([]).minutes == nil, "no sleep records not zero")
        let mixed = aggregate([record(60, 180, .core), record(120, 240, .unspecified, "sourceB")])
        check(mixed.minutes == 180 && mixed.confidence == .mixedSources, "mixed sources union without confident comparison")
        check(aggregate([record(-60, 60, .core)]).minutes == 60 && aggregate([record(-60, 60, .core)]).confidence == .partial, "window clipping")
        check(aggregate([record(60, 120, .unknown), record(140, 130, .core)]).minutes == nil, "unknown and invalid intervals excluded")
        check(aggregate([record(60, 120, .core), record(60, 120, .awake)]).minutes == nil, "all awake overlap no usable duration")

        check(HealthAvailability.state(for: [.sleep: .available, .hrv: .noSamplesOrPermission]) == .partial, "sleep without HRV")
        check(HealthAvailability.state(for: [.steps: .available, .sleep: .noSamplesOrPermission]) == .partial, "steps without sleep")
        check(HealthAvailability.state(for: [.workouts: .available, .restingHeartRate: .error]) == .partial, "workouts survive heart query error")
        check(HealthAvailability.state(for: [.sleep: .noSamplesOrPermission, .steps: .unsupported]) == .noReadableData, "all data unavailable")
        check(HealthAvailability.state(for: [.sleep: .error, .steps: .noSamplesOrPermission]) == .failed, "all unavailable with error")
        check(HealthAvailability.state(for: Dictionary(uniqueKeysWithValues: HealthMetricKind.allCases.map { ($0, .available) })) == .ready, "all supported metrics available")

        check(HealthSourceClassifier.classify(bundleID: "com.garmin.connect.mobile", deviceModel: nil) == .garmin, "Garmin bundle classification")
        check(HealthSourceClassifier.classify(bundleID: "com.apple.health", deviceModel: "Watch") == .appleWatch, "Apple Watch classification")
        check(HealthSourceClassifier.classify(bundleID: "com.apple.health", deviceModel: "iPhone") == .iPhone, "iPhone classification")
        check(HealthSourceClassifier.classify(bundleID: "org.example.garminlike", deviceModel: nil) == .other, "unknown source not assumed Garmin")

        var records: [DailyHealthSummary] = []
        for day in 0...5 {
            records.append(DailyHealthSummary(date: time(Double(day * 1440)), provider: .appleHealth, sourceDevice: "Test source", sleepMinutes: 450, sleepEfficiency: nil, bedtimeMinutes: nil, wakeMinutes: nil, restingHeartRate: nil, heartRateVariability: nil, respiratoryRate: nil, temperatureDeviation: nil, steps: nil, activeEnergy: nil, workoutLoad: nil, sleepConfidence: .complete))
        }
        records[5].sleepConfidence = .partial
        check(HealthInsightsEngine.buildSnapshot(from: records).sleepDifferenceMinutes == nil, "partial sleep excludes comparison")
        records[5].sleepConfidence = .mixedSources
        check(HealthInsightsEngine.buildSnapshot(from: records).sleepDifferenceMinutes == nil, "mixed sleep excludes comparison")
        records[5].sleepConfidence = .complete
        check(HealthInsightsEngine.buildSnapshot(from: Array(records.suffix(5))).sleepDifferenceMinutes == nil, "fewer than five prior nights")
    }
}
