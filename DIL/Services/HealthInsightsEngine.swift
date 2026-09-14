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

struct HealthInsightSnapshot: Hashable {
    var sleepScore: Int
    var recoveryScore: Int
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
    static func makePreviewSnapshot() -> HealthInsightSnapshot {
        let summaries = previewSummaries()
        return buildSnapshot(from: summaries)
    }

    static func buildSnapshot(from summaries: [DailyHealthSummary]) -> HealthInsightSnapshot {
        guard let today = summaries.sorted(by: { $0.date < $1.date }).last else {
            return HealthInsightSnapshot(
                sleepScore: 0,
                recoveryScore: 0,
                activityLabel: "No data",
                dataQuality: "Connect Apple Health or Garmin to begin.",
                dailySummary: "No wearable data has been imported yet.",
                focusRecommendation: "Connect a wearable source to build your personal baseline.",
                sleepDrivers: [],
                recoveryDrivers: [],
                unusualSignals: [],
                baselineDays: 0
            )
        }

        let history = summaries.filter { Calendar.current.startOfDay(for: $0.date) < Calendar.current.startOfDay(for: today.date) }
        let sleepBaseline = baseline(for: .sleepMinutes, in: history, days: 30)
        let hrvBaseline = baseline(for: .heartRateVariability, in: history, days: 30)
        let rhrBaseline = baseline(for: .restingHeartRate, in: history, days: 30)
        let respirationBaseline = baseline(for: .respiratoryRate, in: history, days: 30)

        let sleepResult = scoreSleep(today: today, baseline: sleepBaseline, history: history)
        let recoveryResult = scoreRecovery(
            today: today,
            sleepScore: sleepResult.score,
            hrvBaseline: hrvBaseline,
            rhrBaseline: rhrBaseline,
            respirationBaseline: respirationBaseline
        )
        let unusualSignals = detectUnusualSignals(
            today: today,
            hrvBaseline: hrvBaseline,
            rhrBaseline: rhrBaseline,
            respirationBaseline: respirationBaseline
        )

        return HealthInsightSnapshot(
            sleepScore: sleepResult.score,
            recoveryScore: recoveryResult.score,
            activityLabel: activityLabel(for: today),
            dataQuality: dataQualityLabel(historyCount: history.count, today: today),
            dailySummary: dailySummary(today: today, sleepScore: sleepResult.score, recoveryScore: recoveryResult.score, unusualSignals: unusualSignals),
            focusRecommendation: recommendation(sleepScore: sleepResult.score, recoveryScore: recoveryResult.score, unusualSignals: unusualSignals),
            sleepDrivers: sleepResult.drivers,
            recoveryDrivers: recoveryResult.drivers,
            unusualSignals: unusualSignals,
            baselineDays: min(history.count, 30)
        )
    }

    private static func scoreSleep(today: DailyHealthSummary, baseline: PersonalBaseline?, history: [DailyHealthSummary]) -> (score: Int, drivers: [HealthScoreDriver]) {
        var score = 55.0
        var drivers: [HealthScoreDriver] = []
        let target = baseline?.mean ?? 465

        if let minutes = today.sleepMinutes {
            let delta = minutes - target
            if abs(delta) <= 35 {
                score += 22
                drivers.append(.init(label: "Duration", detail: "Close to your recent normal.", impact: .positive))
            } else if delta < -60 {
                score -= 18
                drivers.append(.init(label: "Duration", detail: "\(formatMinutes(abs(delta))) below baseline.", impact: .negative))
            } else {
                score += 7
                drivers.append(.init(label: "Duration", detail: "\(formatMinutes(abs(delta))) from baseline.", impact: .neutral))
            }
        } else {
            drivers.append(.init(label: "Duration", detail: "Missing from the connected source.", impact: .neutral))
        }

        if let efficiency = today.sleepEfficiency {
            if efficiency >= 0.88 {
                score += 12
                drivers.append(.init(label: "Efficiency", detail: "\(Int(efficiency * 100))% asleep while in bed.", impact: .positive))
            } else if efficiency < 0.78 {
                score -= 12
                drivers.append(.init(label: "Efficiency", detail: "More awake time than usual.", impact: .negative))
            } else {
                drivers.append(.init(label: "Efficiency", detail: "\(Int(efficiency * 100))% asleep while in bed.", impact: .neutral))
            }
        }

        if let bedtime = today.bedtimeMinutes, let averageBedtime = averageValue(for: .bedtimeMinutes, in: history.suffix(7)) {
            let shift = abs(bedtime - averageBedtime)
            if shift <= 35 {
                score += 11
                drivers.append(.init(label: "Timing", detail: "Bedtime stayed consistent.", impact: .positive))
            } else {
                score -= min(14, shift / 8)
                drivers.append(.init(label: "Timing", detail: "Bedtime shifted by \(formatMinutes(shift)).", impact: .negative))
            }
        }

        let debt = recentSleepDebt(history: history, target: target)
        if debt > 120 {
            score -= 9
            drivers.append(.init(label: "Sleep debt", detail: "\(formatMinutes(debt)) short across recent nights.", impact: .negative))
        }

        return (Int(clamp(score, min: 0, max: 100).rounded()), drivers)
    }

    private static func scoreRecovery(
        today: DailyHealthSummary,
        sleepScore: Int,
        hrvBaseline: PersonalBaseline?,
        rhrBaseline: PersonalBaseline?,
        respirationBaseline: PersonalBaseline?
    ) -> (score: Int, drivers: [HealthScoreDriver]) {
        var score = 50.0 + (Double(sleepScore) - 70) * 0.22
        var drivers = [
            HealthScoreDriver(label: "Sleep", detail: "Sleep score contributed \(sleepScore)/100.", impact: sleepScore >= 75 ? .positive : sleepScore < 60 ? .negative : .neutral)
        ]

        if let hrv = today.heartRateVariability, let baseline = hrvBaseline {
            let percent = percentDelta(hrv, baseline.mean)
            if percent < -0.14 {
                score -= 18
                drivers.append(.init(label: "HRV", detail: "\(Int(abs(percent) * 100))% below baseline.", impact: .negative))
            } else if percent > 0.08 {
                score += 10
                drivers.append(.init(label: "HRV", detail: "Above your recent normal.", impact: .positive))
            } else {
                score += 5
                drivers.append(.init(label: "HRV", detail: "Inside your normal range.", impact: .positive))
            }
        }

        if let restingHR = today.restingHeartRate, let baseline = rhrBaseline {
            let percent = percentDelta(restingHR, baseline.mean)
            if percent > 0.08 {
                score -= 14
                drivers.append(.init(label: "Resting HR", detail: "\(Int(percent * 100))% above baseline.", impact: .negative))
            } else {
                score += 8
                drivers.append(.init(label: "Resting HR", detail: "Normal for you.", impact: .positive))
            }
        }

        if let respiratoryRate = today.respiratoryRate, let baseline = respirationBaseline {
            let percent = percentDelta(respiratoryRate, baseline.mean)
            if percent > 0.07 {
                score -= 8
                drivers.append(.init(label: "Respiration", detail: "Slightly elevated vs baseline.", impact: .negative))
            }
        }

        if let load = today.workoutLoad, load > 80 {
            score -= 6
            drivers.append(.init(label: "Training load", detail: "Recent workout load is high.", impact: .negative))
        }

        return (Int(clamp(score, min: 0, max: 100).rounded()), drivers)
    }

    private static func detectUnusualSignals(
        today: DailyHealthSummary,
        hrvBaseline: PersonalBaseline?,
        rhrBaseline: PersonalBaseline?,
        respirationBaseline: PersonalBaseline?
    ) -> [HealthScoreDriver] {
        var signals: [HealthScoreDriver] = []

        if let hrv = today.heartRateVariability, let baseline = hrvBaseline, percentDelta(hrv, baseline.mean) < -0.15 {
            signals.append(.init(label: "HRV", detail: "\(Int(abs(percentDelta(hrv, baseline.mean)) * 100))% below baseline.", impact: .negative))
        }

        if let restingHR = today.restingHeartRate, let baseline = rhrBaseline, percentDelta(restingHR, baseline.mean) > 0.08 {
            signals.append(.init(label: "Resting HR", detail: "\(Int(percentDelta(restingHR, baseline.mean) * 100))% above baseline.", impact: .negative))
        }

        if let respiratoryRate = today.respiratoryRate, let baseline = respirationBaseline, percentDelta(respiratoryRate, baseline.mean) > 0.07 {
            signals.append(.init(label: "Respiration", detail: "Above recent baseline.", impact: .negative))
        }

        if let temperature = today.temperatureDeviation, temperature >= 0.7 {
            signals.append(.init(label: "Temperature", detail: "+\(String(format: "%.1f", temperature))° from baseline.", impact: .negative))
        }

        return signals.count >= 2 ? signals : []
    }

    private static func baseline(for metric: HealthMetricType, in summaries: [DailyHealthSummary], days: Int) -> PersonalBaseline? {
        let values = summaries.suffix(days).compactMap { value(for: metric, in: $0) }
        guard values.count >= 5 else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let variability = sqrt(variance)
        return PersonalBaseline(
            metric: metric,
            windowDays: days,
            mean: mean,
            normalLow: mean - variability,
            normalHigh: mean + variability,
            variability: variability,
            sampleCount: values.count
        )
    }

    private static func value(for metric: HealthMetricType, in summary: DailyHealthSummary) -> Double? {
        switch metric {
        case .sleepMinutes: summary.sleepMinutes
        case .sleepEfficiency: summary.sleepEfficiency
        case .bedtimeMinutes: summary.bedtimeMinutes
        case .wakeMinutes: summary.wakeMinutes
        case .restingHeartRate: summary.restingHeartRate
        case .heartRateVariability: summary.heartRateVariability
        case .respiratoryRate: summary.respiratoryRate
        case .temperatureDeviation: summary.temperatureDeviation
        case .steps: summary.steps
        case .activeEnergy: summary.activeEnergy
        case .workoutLoad: summary.workoutLoad
        }
    }

    private static func averageValue(for metric: HealthMetricType, in summaries: ArraySlice<DailyHealthSummary>) -> Double? {
        let values = summaries.compactMap { value(for: metric, in: $0) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func recentSleepDebt(history: [DailyHealthSummary], target: Double) -> Double {
        history.suffix(3).compactMap(\.sleepMinutes).reduce(0) { debt, minutes in
            debt + max(0, target - minutes)
        }
    }

    private static func dailySummary(today: DailyHealthSummary, sleepScore: Int, recoveryScore: Int, unusualSignals: [HealthScoreDriver]) -> String {
        let sleep = today.sleepMinutes.map(formatMinutes) ?? "missing sleep"
        if unusualSignals.isEmpty {
            return "Sleep \(sleep), sleep score \(sleepScore), recovery \(recoveryScore). Your current wearable data looks steady against your recent baseline."
        }
        return "Sleep \(sleep), sleep score \(sleepScore), recovery \(recoveryScore). A few recovery signals are outside your usual range today."
    }

    private static func recommendation(sleepScore: Int, recoveryScore: Int, unusualSignals: [HealthScoreDriver]) -> String {
        if !unusualSignals.isEmpty {
            return "Take today a little easier and pay attention to how you feel. This is a wellness signal, not a diagnosis."
        }
        if sleepScore < 70 {
            return "Keep tonight's bedtime inside your usual window and give yourself a longer wind-down."
        }
        if recoveryScore < 70 {
            return "Choose a lighter training day or add more recovery between intense blocks."
        }
        return "Keep the routine steady: consistent bedtime, normal activity, and a short reflection tonight."
    }

    private static func activityLabel(for summary: DailyHealthSummary) -> String {
        guard let steps = summary.steps else { return "Missing" }
        switch steps {
        case 0..<4000:
            return "Light"
        case 4000..<9000:
            return "Normal"
        default:
            return "Active"
        }
    }

    private static func dataQualityLabel(historyCount: Int, today: DailyHealthSummary) -> String {
        let availableSignals = [
            today.sleepMinutes,
            today.restingHeartRate,
            today.heartRateVariability,
            today.respiratoryRate,
            today.steps
        ].compactMap { $0 }.count
        if historyCount < 7 {
            return "Learning baseline"
        }
        return "\(min(historyCount, 30))-day baseline · \(availableSignals)/5 signals"
    }

    private static func percentDelta(_ value: Double, _ baseline: Double) -> Double {
        guard baseline != 0 else { return 0 }
        return (value - baseline) / baseline
    }

    private static func formatMinutes(_ minutes: Double) -> String {
        let total = max(0, Int(minutes.rounded()))
        return "\(total / 60)h \(total % 60)m"
    }

    private static func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private static func previewSummaries() -> [DailyHealthSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sleep: [Double] = [438, 462, 455, 481, 470, 452, 466, 474, 458, 489, 450, 468, 456, 461]
        let hrv: [Double] = [62, 60, 64, 59, 61, 63, 60, 65, 62, 61, 58, 60, 59, 49]
        let restingHR: [Double] = [54, 55, 53, 54, 56, 55, 54, 53, 55, 54, 56, 55, 54, 59]
        let respiration: [Double] = [14.5, 14.8, 14.6, 14.7, 14.4, 14.8, 14.6, 14.5, 14.7, 14.6, 14.8, 14.7, 14.6, 15.3]

        return sleep.indices.map { index in
            let offset = sleep.count - 1 - index
            return DailyHealthSummary(
                date: calendar.date(byAdding: .day, value: -offset, to: today) ?? today,
                provider: .garmin,
                sourceDevice: "Garmin Forerunner 165 via Apple Health",
                sleepMinutes: sleep[index],
                sleepEfficiency: index == sleep.indices.last ? 0.84 : 0.87 + Double(index % 4) * 0.01,
                bedtimeMinutes: 23 * 60 + 18 + Double(index % 5) * 8,
                wakeMinutes: 7 * 60 + 4 + Double(index % 4) * 9,
                restingHeartRate: restingHR[index],
                heartRateVariability: hrv[index],
                respiratoryRate: respiration[index],
                temperatureDeviation: index == sleep.indices.last ? 0.3 : 0.0,
                steps: index == sleep.indices.last ? 7420 : Double(6200 + index * 210),
                activeEnergy: index == sleep.indices.last ? 540 : 470,
                workoutLoad: index == sleep.indices.last ? 62 : 44
            )
        }
    }
}
