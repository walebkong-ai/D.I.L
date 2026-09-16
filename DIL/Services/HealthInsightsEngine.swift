import Foundation

enum HealthDataProvider: String, CaseIterable, Identifiable, Hashable {
    case appleHealth = "Apple Health"
    case garmin = "Garmin"

    var id: String { rawValue }
}

enum HealthMetricType: String, CaseIterable, Identifiable, Hashable {
    case sleepMinutes
    case sleepEfficiency
    case bedtimeMinutes
    case wakeMinutes
    case restingHeartRate
    case heartRateVariability
    case respiratoryRate
    case temperatureDeviation
    case steps
    case activeEnergy
    case workoutLoad

    var id: String { rawValue }
}

struct NormalizedHealthMetric: Identifiable, Hashable {
    let id = UUID()
    var provider: HealthDataProvider
    var type: HealthMetricType
    var value: Double
    var unit: String
    var startDate: Date
    var endDate: Date
    var sourceDevice: String
    var recordedAt: Date
}

struct DailyHealthSummary: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var provider: HealthDataProvider
    var sourceDevice: String
    var sleepMinutes: Double?
    var sleepEfficiency: Double?
    var bedtimeMinutes: Double?
    var wakeMinutes: Double?
    var restingHeartRate: Double?
    var heartRateVariability: Double?
    var respiratoryRate: Double?
    var temperatureDeviation: Double?
    var steps: Double?
    var activeEnergy: Double?
    var workoutLoad: Double?
    var sleepConfidence: SleepDataConfidence = .unknown
}

struct PersonalBaseline: Hashable {
    var metric: HealthMetricType
    var windowDays: Int
    var mean: Double
    var normalLow: Double
    var normalHigh: Double
    var variability: Double
    var sampleCount: Int
}

struct HealthScoreDriver: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var detail: String
    var impact: DriverImpact
}

enum DriverImpact: Hashable {
    case positive
    case neutral
    case negative

    var symbol: String {
        switch self {
        case .positive: "checkmark.circle.fill"
        case .neutral: "minus.circle.fill"
        case .negative: "arrow.down.circle.fill"
        }
    }
}

enum HealthReadState: Equatable {
    case notRequested, unavailable, loading, noReadableData, partial, ready, failed
}

struct HealthInsightSnapshot: Hashable {
    var sleepScore: Int?
    var recoveryScore: Int?
    var activityLabel: String
    var dataQuality: String
    var dailySummary: String
    var focusRecommendation: String
    var sleepDrivers: [HealthScoreDriver]
    var recoveryDrivers: [HealthScoreDriver]
    var unusualSignals: [HealthScoreDriver]
    var baselineDays: Int
    var sleepDifferenceMinutes: Double? = nil
}

enum HealthInsightsEngine {
    static func buildSnapshot(from summaries: [DailyHealthSummary]) -> HealthInsightSnapshot {
        let sorted = summaries.sorted { $0.date < $1.date }
        guard let today = sorted.last else {
            return HealthInsightSnapshot(sleepScore: nil, recoveryScore: nil, activityLabel: "No data",
                dataQuality: "No readable Health samples", dailySummary: "No health data is available.",
                focusRecommendation: "Check Health permissions or try again after your device syncs.",
                sleepDrivers: [], recoveryDrivers: [], unusualSignals: [], baselineDays: 0)
        }
        let history = sorted.dropLast().suffix(30)
        let sleepHistory = history.filter { $0.sleepConfidence == .complete }.compactMap(\.sleepMinutes).filter { $0.isFinite && $0 > 0 }
        var difference: Double?
        if let sleep = today.sleepMinutes, sleep.isFinite, sleep > 0, today.sleepConfidence == .complete, sleepHistory.count >= 5 {
            let baseline = sleepHistory.reduce(0, +) / Double(sleepHistory.count)
            difference = sleep - baseline
        }
        let metrics = [today.sleepMinutes, today.steps, today.activeEnergy, today.restingHeartRate, today.heartRateVariability, today.workoutLoad].compactMap { $0 }
        // A duration comparison has a clear unit; numerical health grades lack validation.
        return HealthInsightSnapshot(sleepScore: nil, recoveryScore: nil,
            activityLabel: today.steps.map { "\(Int($0)) steps" } ?? "No steps data",
            dataQuality: "\(metrics.count)/6 recorded metrics",
            dailySummary: metrics.isEmpty ? "No readable samples for today." : "Only available Health records are shown. Missing metrics remain unavailable.",
            focusRecommendation: "Use these records for reflection alongside how you feel.",
            sleepDrivers: [], recoveryDrivers: [], unusualSignals: [], baselineDays: sleepHistory.count, sleepDifferenceMinutes: difference)
    }
}
