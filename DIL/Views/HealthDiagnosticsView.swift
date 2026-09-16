#if DEBUG
import SwiftUI

struct HealthDiagnosticsView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        List {
            Section("Development only · memory-only records") {
                LabeledContent("HealthKit", value: HealthAccessService().isHealthDataAvailable ? "Available" : "Unsupported / unavailable")
                LabeledContent("Request state", value: String(describing: appState.healthReadState))
                Text("No samples can mean absent records or denied read permission. The app cannot distinguish these. Sample provenance is limited to the latest 100 per metric over 15 days; totals use Health statistics, not this sample list.")
                Button("Request / refresh Health") { Task { await appState.requestHealthAccess() } }.disabled(appState.isRequestingHealth)
            }
            ForEach(HealthMetricKind.allCases, id: \.self) { metric in
                Section(metric.rawValue) {
                    LabeledContent("Today's read", value: appState.healthMetricStatuses[metric]?.rawValue ?? "Not requested")
                    if let summary = appState.latestHealthSummary { LabeledContent("Today's value", value: formatted(metric, summary)) }
                    LabeledContent("Recent samples", value: appState.diagnosticStatuses[metric]?.rawValue ?? "Not requested")
                    let records = appState.healthDiagnostics.filter { $0.metric == metric }
                    if let latest = records.first {
                        LabeledContent("Latest usable record", value: latest.end.formatted())
                        Text(latest.value)
                        LabeledContent("Source", value: latest.sourceName)
                    }
                    let sources = Array(Set(records.map(\.sourceName))).sorted()
                    Text(sources.isEmpty ? "No source records available" : "Inspected sources: " + sources.joined(separator: ", "))
                    DisclosureGroup("Sample source details") {
                        ForEach(records) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.value).font(.headline)
                                Text("\(record.start.formatted()) → \(record.end.formatted())")
                                Text("\(record.sourceKind.rawValue): \(record.sourceName)")
                                Text(record.bundleID)
                                Text("Source revision: \(record.version ?? "not provided")")
                                Text("Device: \(record.deviceName ?? "not provided") · \(record.deviceModel ?? "not provided")")
                            }.font(.footnote).textSelection(.enabled)
                        }
                    }
                }
            }
        }.navigationTitle("Health Diagnostics")
    }
}
#endif
