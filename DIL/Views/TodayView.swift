import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { screenWidth in
                    if let message = appState.persistenceMessage {
                        Text(message).font(.footnote).foregroundStyle(.red)
                        Button("Retry loading goals") { appState.retryActivityLoad() }
                    }
                    HeaderView(
                        eyebrow: formattedDate,
                        title: "Good morning, \(appState.user.name)",
                        systemImage: "sun.max.fill"
                    )

                    ScoreHero(
                        points: appState.dailyPointTotal,
                        maxPoints: appState.maxDailyPoints,
                        progress: appState.dailyProgress,
                        isCompact: screenWidth < 390
                    )

                    TodaySummaryStrip(
                        completed: appState.dailyPlan.tasks.filter(\.isComplete).count,
                        total: appState.dailyPlan.tasks.count,
                        categories: appState.dailyPlan.categories.filter { $0.pointsEarned > 0 }.count,
                        weeklyPoints: appState.user.weeklyPoints
                    )

                    if appState.healthReadState == .partial || appState.healthReadState == .ready {
                        HealthInsightsCard(snapshot: appState.healthInsightSnapshot, isCompact: screenWidth < 390)
                        if let summary = appState.latestHealthSummary {
                            RecordedHealthCard(summary: summary)
                        }
                    } else {
                        EmptyStatePanel(
                            icon: "heart.text.square.fill",
                            title: "Health insights are waiting",
                            detail: appState.healthReadState == .notRequested ? "Connect Health from Profile to load available records." : appState.healthMessage,
                            color: .dilPurple
                        )
                    }

                    SectionHeader(title: "Category Pace", detail: "\(appState.dailyPointTotal) pts")
                    CategoryGrid(categories: appState.dailyPlan.categories, screenWidth: screenWidth)

                    InsightCard(insight: appState.dailyPlan.insights[0])

                    SectionHeader(title: "Today’s Goals", detail: "\(appState.dailyPlan.tasks.filter(\.isComplete).count)/\(appState.dailyPlan.tasks.count) done")
                    VStack(spacing: 12) {
                        ForEach(appState.dailyPlan.tasks) { task in
                            TaskRow(task: task, categoryColor: categoryColor(for: task.categoryName), isCompact: screenWidth < 390) {
                                appState.completeTask(task)
                            }
                        }
                    }

                    if appState.dailyPlan.tasks.isEmpty {
                        EmptyStatePanel(
                            icon: "target",
                            title: "Plan the first move",
                            detail: "Add a goal from the Goals tab and it will show up here with points for today.",
                            color: .dilGreen
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }

    private var formattedDate: String {
        appState.dailyPlan.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func categoryColor(for name: String) -> Color {
        appState.dailyPlan.categories.first(where: { $0.name == name })?.color ?? .dilInk
    }
}

private struct TodaySummaryStrip: View {
    var completed: Int
    var total: Int
    var categories: Int
    var weeklyPoints: Int

    var body: some View {
        HStack(spacing: 10) {
            MetricBlock(title: "Done", value: "\(completed)/\(total)", detail: "goals", color: .dilGreen)
            MetricBlock(title: "Range", value: "\(categories)", detail: "categories", color: .dilBlue)
            MetricBlock(title: "Week", value: "\(weeklyPoints)", detail: "points", color: .dilOrange)
        }
    }
}

private struct RecordedHealthCard: View {
    var summary: DailyHealthSummary

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Recorded Today", detail: summary.sourceDevice)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                    HealthMetricPill(title: "Sleep", value: summary.sleepMinutes.map { "\(Int($0)) min" } ?? "Unavailable", color: .dilBlue)
                    HealthMetricPill(title: "Steps", value: summary.steps.map { "\((Int($0)))" } ?? "Unavailable", color: .dilGreen)
                    HealthMetricPill(title: "Energy", value: summary.activeEnergy.map { "\(Int($0)) kcal" } ?? "Unavailable", color: .dilOrange)
                    HealthMetricPill(title: "RHR", value: summary.restingHeartRate.map { "\(Int($0)) bpm" } ?? "Unavailable", color: .dilPurple)
                    HealthMetricPill(title: "HRV", value: summary.heartRateVariability.map { "\(Int($0)) ms" } ?? "Unavailable", color: .dilGold)
                    HealthMetricPill(title: "Workout", value: summary.workoutLoad.map { "\(Int($0)) min" } ?? "Unavailable", color: .mint)
                }
            }
        }
    }
}

private struct HealthMetricPill: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
                .textCase(.uppercase)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(Color.dilInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct HealthInsightsCard: View {
    var snapshot: HealthInsightSnapshot
    var isCompact: Bool

    var body: some View {
        Card(background: Color.dilPurple.opacity(0.17), padding: isCompact ? 16 : 18) {
            VStack(alignment: .leading, spacing: isCompact ? 14 : 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dilPurple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Insights")
                            .font(.title3.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(snapshot.dataQuality)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dilMuted)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    HealthScoreTile(title: "Sleep", value: snapshot.sleepScore, color: .dilBlue, isCompact: isCompact)
                    HealthScoreTile(title: "Recovery", value: snapshot.recoveryScore, color: .dilGreen, isCompact: isCompact)
                    HealthActivityTile(label: snapshot.activityLabel, isCompact: isCompact)
                }

                Text(snapshot.dailySummary)
                    .font(.subheadline)
                    .foregroundStyle(Color.dilMuted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus today")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dilMuted)
                        .textCase(.uppercase)
                    Text(snapshot.focusRecommendation)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.dilInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 8) {
                    ForEach(Array(snapshot.recoveryDrivers.prefix(3))) { driver in
                        HealthDriverRow(driver: driver)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HealthScoreTile: View {
    var title: String
    var value: Int?
    var color: Color
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value.map(String.init) ?? "—")
                    .font(.system(size: isCompact ? 28 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("/100")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dilMuted)
            }
            if let value { ProgressBar(progress: Double(value) / 100, color: color) }
        }
        .padding(isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct HealthActivityTile: View {
    var label: String
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: isCompact ? 23 : 27, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct HealthDriverRow: View {
    var driver: HealthScoreDriver

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: driver.impact.symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(driver.label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dilInk)
                Text(driver.detail)
                    .font(.caption)
                    .foregroundStyle(Color.dilMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var color: Color {
        switch driver.impact {
        case .positive: .dilGreen
        case .neutral: .dilGold
        case .negative: .dilOrange
        }
    }
}

private struct ScoreHero: View {
    var points: Int
    var maxPoints: Int
    var progress: Double
    var isCompact: Bool

    var body: some View {
        Card(background: .dilInk, padding: isCompact ? 16 : 18) {
            VStack(alignment: .leading, spacing: isCompact ? 14 : 18) {
                HStack {
                    Text("Today Score")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.78))
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.dilGold)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(points)")
                        .font(.system(size: isCompact ? 48 : 58, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("/ \(maxPoints) pts")
                        .font((isCompact ? Font.body : Font.title3).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                ProgressBar(progress: progress, color: .dilGold)

                Text("Points come from your completed daily goals.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
    }
}

private struct CategoryGrid: View {
    var categories: [PointCategory]
    var screenWidth: CGFloat

    private var columns: [GridItem] {
        let minimum = screenWidth < 390 ? 144.0 : 160.0
        return [GridItem(.adaptive(minimum: minimum), spacing: 12)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories) { category in
                Card(background: category.color.opacity(0.22)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(category.color)
                        Text(category.name)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text("\(category.pointsEarned) / \(category.dailyCap) pts")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dilMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        ProgressBar(progress: category.progress, color: category.color)
                    }
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
                }
            }
        }
    }
}

private struct InsightCard: View {
    var insight: Insight

    var body: some View {
        Card(background: Color.dilBlue.opacity(0.20)) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.dilBlue)
                VStack(alignment: .leading, spacing: 7) {
                    Text(insight.title)
                        .font(.headline)
                    Text(insight.message)
                        .font(.subheadline)
                        .foregroundStyle(Color.dilMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct TaskRow: View {
    var task: DailyTask
    var categoryColor: Color
    var isCompact: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 10 : 14) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(task.isComplete ? Color.dilGreen : categoryColor.opacity(0.15))
                    .frame(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50)
                    .overlay {
                        Image(systemName: task.isComplete ? "checkmark" : task.icon)
                            .font(.headline)
                            .foregroundStyle(task.isComplete ? Color.white : categoryColor)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(Color.dilInk)
                    Text(task.detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.dilMuted)
                        .lineLimit(2)
                }

                Spacer()

                Text("+\(task.points)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(task.isComplete ? Color.dilGreen : categoryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(isCompact ? 12 : 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.dilLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.points) points")
    }
}
