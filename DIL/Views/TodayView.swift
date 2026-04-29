import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        HeaderView(
                            eyebrow: formattedDate,
                            title: "Good morning, \(appState.user.name)",
                            systemImage: "sun.max.fill"
                        )

                        ScoreHero(
                            points: appState.dailyPointTotal,
                            maxPoints: appState.maxDailyPoints,
                            progress: appState.dailyProgress
                        )

                        CategoryGrid(categories: appState.dailyPlan.categories)

                        InsightCard(insight: appState.dailyPlan.insights[0])

                        VStack(spacing: 12) {
                            ForEach(appState.dailyPlan.tasks) { task in
                                TaskRow(task: task) {
                                    appState.completeTask(task)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var formattedDate: String {
        appState.dailyPlan.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

private struct ScoreHero: View {
    var points: Int
    var maxPoints: Int
    var progress: Double

    var body: some View {
        Card(background: .dilInk) {
            VStack(alignment: .leading, spacing: 18) {
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
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/ \(maxPoints) pts")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
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

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(categories) { category in
                Card(background: category.color.opacity(0.22)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(category.color)
                        Text(category.name)
                            .font(.headline)
                        Text("\(category.pointsEarned) / \(category.dailyCap) pts")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dilMuted)
                        ProgressBar(progress: category.progress, color: category.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(task.isComplete ? Color.dilGreen : Color.white)
                    .frame(width: 50, height: 50)
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
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.points) points")
    }
}
