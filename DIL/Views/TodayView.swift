import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { screenWidth in
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

                    HealthInsightsCard(snapshot: appState.healthInsightSnapshot, isCompact: screenWidth < 390)

                    CategoryGrid(categories: appState.dailyPlan.categories, screenWidth: screenWidth)

                    InsightCard(insight: appState.dailyPlan.insights[0])

                    VStack(spacing: 12) {
                        ForEach(appState.dailyPlan.tasks) { task in
                            TaskRow(task: task, isCompact: screenWidth < 390) {
                                appState.completeTask(task)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }

    private var formattedDate: String {
        appState.dailyPlan.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
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
    var value: Int
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
                Text("\(value)")
                    .font(.system(size: isCompact ? 28 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("/100")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dilMuted)
            }
            ProgressBar(progress: Double(value) / 100, color: color)
        }
        .padding(isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
            ProgressBar(progress: label == "Active" ? 0.9 : label == "Normal" ? 0.62 : 0.28, color: .dilOrange)
        }
        .padding(isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

                Text("You are 90 points from passing Maya this week.")
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
    var isCompact: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 10 : 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(task.isComplete ? Color.dilGreen : Color.white)
                    .frame(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50)
                    .overlay {
                        Image(systemName: task.isComplete ? "checkmark" : task.icon)
                            .font(.headline)
                            .foregroundStyle(task.isComplete ? Color.white : Color.dilInk)
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
                    .foregroundStyle(task.isComplete ? Color.dilGreen : Color.dilOrange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(isCompact ? 12 : 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.points) points")
    }
}
