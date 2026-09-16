import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    private var available: Int {
        appState.dailyPlan.categories.reduce(0) { total, category in
            total + min(category.dailyCap, appState.dailyPlan.tasks.filter { $0.categoryName == category.name }.reduce(0) { $0 + $1.points })
        }
    }
    private var progress: Double { available > 0 ? Double(appState.dailyPointTotal) / Double(available) : 0 }
    private var remaining: [DailyTask] { appState.dailyPlan.tasks.filter { !$0.isComplete }.sorted { $0.points > $1.points } }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    HeaderView(eyebrow: appState.dailyPlan.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                               title: appState.user.name == "You" ? "Good morning" : "Good morning, \(appState.user.name)", systemImage: "sun.max.fill")
                    if let message = appState.persistenceMessage {
                        Text(message).foregroundStyle(.red)
                        Button("Retry loading goals") { appState.retryActivityLoad() }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Today")
                            Text("\(appState.dailyPointTotal) pts").font(.largeTitle.bold())
                            Text(available == 0 ? "Build your day" : remaining.isEmpty ? "Today's goals complete" : progress >= 0.5 ? "Good progress" : "Getting started").font(.headline)
                            ProgressBar(progress: progress, color: .dilAccent)
                            Text(available == 0 ? "Add a daily goal to get started." : "\(Int(progress * 100))% of today's \(available) available points")
                                .font(.subheadline).foregroundStyle(Color.dilMuted)
                            NavigationLink("View points breakdown") { PointsDetailView() }
                        }
                    }
                    SectionHeader(title: "Top priorities")
                    if remaining.isEmpty {
                        EmptyStatePanel(icon: "checkmark.circle", title: appState.dailyPlan.tasks.isEmpty ? "No goals yet" : "Nothing left today",
                                        detail: appState.dailyPlan.tasks.isEmpty ? "Create your first daily goal." : "You've completed all of today's goals.")
                    } else {
                        ForEach(remaining.prefix(3)) { task in GoalSummaryRow(task: task) }
                    }
                    NavigationLink("View all goals") { GoalsView() }.frame(maxWidth: .infinity, alignment: .leading)
                    HealthOverviewView()
                    SectionHeader(title: "Goals")
                    Text("\(appState.dailyPlan.tasks.filter(\.isComplete).count) of \(appState.dailyPlan.tasks.count) complete")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ProgressBar(progress: appState.dailyPlan.tasks.isEmpty ? 0 : Double(appState.dailyPlan.tasks.filter(\.isComplete).count) / Double(appState.dailyPlan.tasks.count), color: .dilAccent)
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PointsDetailView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        List {
            Section("Today's points") {
                ForEach(appState.dailyPlan.categories) { category in
                    MetricRow(title: category.name, value: "\(category.pointsEarned) pts", detail: "Daily limit: \(category.dailyCap) pts")
                }
            }
            Section("How points work") { Text("Completed goals earn points up to each category's daily limit. Today's available points reflect the goals you have added, within those limits.") }
        }.navigationTitle("Points").navigationBarTitleDisplayMode(.inline)
    }
}
