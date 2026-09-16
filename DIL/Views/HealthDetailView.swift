import SwiftUI

enum HealthDetailKind: String, CaseIterable { case sleep = "Sleep", recovery = "Recovery", activity = "Activity" }

struct HealthOverviewView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Health").font(.title3.weight(.bold)).accessibilityAddTraits(.isHeader)
                if appState.isRequestingHealth { ProgressView("Loading records") }
                ForEach(HealthDetailKind.allCases, id: \.self) { kind in
                    NavigationLink {
                        HealthDetailView(kind: kind)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(kind.rawValue).font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right").accessibilityHidden(true)
                            }
                            Text(primaryValue(kind, summary: appState.latestHealthSummary)).font(.title3.weight(.semibold))
                            Text(kind == .recovery ? "Recorded signals; no recovery grade." : "Available Health records. View details.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }.foregroundStyle(.primary).frame(minHeight: 44)
                    }
                }
                if appState.latestHealthSummary == nil {
                    Text(appState.healthReadState == .notRequested ? "Connect Health from Profile when you're ready." : appState.healthMessage)
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private func duration(_ minutes: Double) -> String {
    let rounded = Int(minutes.rounded())
    return "\(rounded / 60)h \(rounded % 60)m"
}

private func primaryValue(_ kind: HealthDetailKind, summary: DailyHealthSummary?) -> String {
    guard let summary else { return "Unavailable" }
    switch kind {
    case .sleep: return summary.sleepMinutes.map { duration($0) + (summary.sleepConfidence == .complete ? " recorded" : " · provisional") } ?? "Unavailable"
    case .recovery: return summary.restingHeartRate != nil || summary.heartRateVariability != nil ? "Signals available" : "Unavailable"
    case .activity:
        if let steps = summary.steps { return "\(Int(steps)) steps" }
        if let energy = summary.activeEnergy { return "\(Int(energy)) active kcal" }
        return summary.workoutLoad.map { duration($0) + " in workouts" } ?? "Unavailable"
    }
}

struct HealthDetailView: View {
    @EnvironmentObject private var appState: AppState
    let kind: HealthDetailKind

    var body: some View {
        List {
            Section {
                Text(primaryValue(kind, summary: appState.latestHealthSummary)).font(.title2.weight(.bold))
                if kind == .sleep {
                    if let delta = appState.healthInsightSnapshot.sleepDifferenceMinutes {
                        Text("About \(Int(abs(delta).rounded())) minutes \(delta >= 0 ? "longer" : "shorter") than your recorded recent average.")
                    } else {
                        Text("Comparison unavailable for partial or mixed-source windows, or fewer than five usable prior nights.")
                    }
                    Text("Duration describes recorded asleep intervals, not sleep quality. Awake and in-bed time are not counted as sleep.")
                } else if kind == .recovery {
                    Text("A recovery score is not calculated. These measurements do not establish readiness to train or diagnose a condition.")
                } else {
                    Text("Totals use available Health records. Missing measurements are unavailable, not zero.")
                }
            }
            Section("Supporting records") {
                if let summary = appState.latestHealthSummary {
                    ForEach(metrics, id: \.self) { metric in
                        LabeledContent(metric.rawValue, value: formatted(metric, summary))
                    }
                } else { Text("No records loaded.") }
            }
            Section(kind == .sleep ? "Has recorded sleep duration changed this week?" : "Recent records") {
                ForEach(Array(appState.healthHistory.suffix(7)), id: \.date) { summary in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())).font(.headline)
                        ForEach(metrics, id: \.self) { metric in
                            Text("\(metric.rawValue): \(formatted(metric, summary))").font(.body)
                        }
                    }
                }
                if appState.healthHistory.isEmpty { Text("No history loaded.") }
            }
        }.navigationTitle(kind.rawValue)
    }

    private var metrics: [HealthMetricKind] {
        switch kind { case .sleep: [.sleep]; case .recovery: [.restingHeartRate, .hrv]; case .activity: [.steps, .activeEnergy, .workouts] }
    }
}

func formatted(_ metric: HealthMetricKind, _ summary: DailyHealthSummary) -> String {
    switch metric {
    case .sleep: summary.sleepMinutes.map(duration) ?? "Unavailable"
    case .steps: summary.steps.map { "\(Int($0))" } ?? "Unavailable"
    case .activeEnergy: summary.activeEnergy.map { "\(Int($0)) kcal" } ?? "Unavailable"
    case .restingHeartRate: summary.restingHeartRate.map { "\(Int($0)) bpm" } ?? "Unavailable"
    case .hrv: summary.heartRateVariability.map { "\(Int($0)) ms (SDNN)" } ?? "Unavailable"
    case .workouts: summary.workoutLoad.map(duration) ?? "Unavailable"
    }
}
