import Foundation

enum SleepStage: String { case unspecified, core, deep, rem, awake, inBed, unknown }
enum SleepDataConfidence: String { case complete, partial, mixedSources, insufficient, unknown }

struct SleepRecord {
    let start: Date
    let end: Date
    let stage: SleepStage
    let sourceID: String
}

struct SleepAggregation {
    let minutes: Double?
    let confidence: SleepDataConfidence
}

enum SleepAggregator {
    static func aggregate(_ records: [SleepRecord], window: DateInterval, windowComplete: Bool) -> SleepAggregation {
        let valid = records.filter { $0.start < $0.end && $0.start < window.end && $0.end > window.start }
        let asleep = valid.filter { [.unspecified, .core, .deep, .rem].contains($0.stage) }
        guard !asleep.isEmpty else { return .init(minutes: nil, confidence: .insufficient) }
        func intervals(_ records: [SleepRecord]) -> [DateInterval] {
            merge(records.map { DateInterval(start: max(window.start, $0.start), end: min(window.end, $0.end)) })
        }
        let sleeping = intervals(asleep)
        let awake = intervals(valid.filter { $0.stage == .awake })
        // Both sets are unions, so subtracting their intersections cannot double-count.
        let awakeOverlap = sleeping.reduce(0.0) { total, interval in
            total + awake.reduce(0.0) { $0 + max(0, min(interval.end, $1.end).timeIntervalSince(max(interval.start, $1.start))) }
        }
        let duration = sleeping.reduce(0.0) { $0 + $1.duration } - awakeOverlap
        guard duration > 0 else { return .init(minutes: nil, confidence: .insufficient) }
        let sources = Set(asleep.map(\.sourceID))
        let clipped = asleep.contains { $0.start <= window.start || $0.end >= window.end }
        let confidence: SleepDataConfidence = sources.count > 1 ? .mixedSources : (!windowComplete || clipped) ? .partial : .complete
        return .init(minutes: duration / 60, confidence: confidence)
    }

    private static func merge(_ intervals: [DateInterval]) -> [DateInterval] {
        var result: [DateInterval] = []
        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let last = result.last, interval.start <= last.end {
                result[result.count - 1] = .init(start: last.start, end: max(last.end, interval.end))
            } else { result.append(interval) }
        }
        return result
    }
}

enum HealthMetricKind: String, CaseIterable {
    case sleep = "Sleep", steps = "Steps", restingHeartRate = "Resting heart rate"
    case hrv = "HRV (SDNN)", activeEnergy = "Active energy", workouts = "Workouts"
}

enum MetricReadStatus: String {
    case available = "Available"
    case noSamplesOrPermission = "No samples / read permission unavailable"
    case unsupported = "Unsupported"
    case error = "Error"
}

enum HealthSourceKind: String { case garmin = "Garmin Connect", appleWatch = "Apple Watch", iPhone = "iPhone", apple = "Apple source", other = "Other source" }

enum HealthSourceClassifier {
    static func classify(bundleID: String, deviceModel: String?) -> HealthSourceKind {
        if bundleID.lowercased() == "com.garmin.connect.mobile" { return .garmin }
        if bundleID.hasPrefix("com.apple.") {
            if deviceModel?.lowercased().contains("watch") == true { return .appleWatch }
            if deviceModel?.lowercased().contains("iphone") == true { return .iPhone }
            return .apple
        }
        return .other
    }
}

enum HealthAvailability {
    static func state(for statuses: [HealthMetricKind: MetricReadStatus]) -> HealthReadState {
        let available = statuses.values.filter { $0 == .available }.count
        if available == HealthMetricKind.allCases.count { return .ready }
        if available > 0 { return .partial }
        return statuses.values.contains(.error) ? .failed : .noReadableData
    }
}

#if DEBUG
struct HealthSourceDiagnostic: Identifiable {
    let id = UUID()
    let metric: HealthMetricKind
    let start: Date
    let end: Date
    let sourceName: String
    let bundleID: String
    let version: String?
    let deviceName: String?
    let deviceModel: String?
    let value: String
    var sourceKind: HealthSourceKind { HealthSourceClassifier.classify(bundleID: bundleID, deviceModel: deviceModel) }
}
#endif
