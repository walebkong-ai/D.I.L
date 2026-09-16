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
        let sleepHistory = history.compactMap(\.sleepMinutes).filter { $0.isFinite && $0 > 0 }
        let hrvHistory = history.compactMap(\.heartRateVariability).filter { $0.isFinite && $0 > 0 }
        let rhrHistory = history.compactMap(\.restingHeartRate).filter { $0.isFinite && $0 > 0 }
        var sleepScore: Int?
        var recoveryScore: Int?
        var sleepDrivers: [HealthScoreDriver] = []
        var recoveryDrivers: [HealthScoreDriver] = []
        if let sleep = today.sleepMinutes, sleep.isFinite, sleep > 0, sleepHistory.count >= 5 {
            let baseline = sleepHistory.reduce(0, +) / Double(sleepHistory.count)
            sleepScore = Int(min(100, max(0, sleep / baseline * 100)).rounded())
            sleepDrivers = [.init(label: "Sleep duration", detail: "Duration relative to your recorded recent average; not a measure of sleep quality.", impact: .neutral)]
        }
        if let sleep = sleepScore, let hrv = today.heartRateVariability, let rhr = today.restingHeartRate,
           hrv.isFinite, rhr.isFinite, hrv > 0, rhr > 0, hrvHistory.count >= 5, rhrHistory.count >= 5 {
            let hrvMean = hrvHistory.reduce(0, +) / Double(hrvHistory.count)
            let rhrMean = rhrHistory.reduce(0, +) / Double(rhrHistory.count)
            let relativeHRV = min(1, hrv / hrvMean)
            let relativeRHR = min(1, rhrMean / rhr)
            recoveryScore = Int((Double(sleep) * 0.5 + relativeHRV * 25 + relativeRHR * 25).rounded())
            recoveryDrivers = [.init(label: "Recorded inputs", detail: "Sleep duration, HRV, and resting heart rate relative to recent averages. This experimental wellness index is not diagnostic.", impact: .neutral)]
        }
        let metrics = [today.sleepMinutes, today.steps, today.activeEnergy, today.restingHeartRate, today.heartRateVariability, today.workoutLoad].compactMap { $0 }
        return HealthInsightSnapshot(sleepScore: sleepScore, recoveryScore: recoveryScore,
            activityLabel: today.steps.map { "\(Int($0)) steps" } ?? "No steps data",
            dataQuality: "\(metrics.count)/6 recorded metrics",
            dailySummary: metrics.isEmpty ? "No readable samples for today." : "Only available Health records are shown. Missing metrics remain unavailable.",
            focusRecommendation: "Use these records for reflection alongside how you feel.",
            sleepDrivers: sleepDrivers, recoveryDrivers: recoveryDrivers, unusualSignals: [], baselineDays: history.count)
    }
}
