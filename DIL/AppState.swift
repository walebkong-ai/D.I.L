import Foundation

final class AppState: ObservableObject {
    @Published var user = UserProfile.sample
    @Published var dailyPlan = DailyPlan.sample
    @Published var leaderboard = Leaderboard.sample
    @Published var healthAuthorizationState: HealthAuthorizationState = .notRequested

    var dailyPointTotal: Int {
        dailyPlan.categories.reduce(0) { $0 + $1.pointsEarned }
    }

    var maxDailyPoints: Int {
        dailyPlan.categories.reduce(0) { $0 + $1.dailyCap }
    }

    var dailyProgress: Double {
        guard maxDailyPoints > 0 else { return 0 }
        return min(Double(dailyPointTotal) / Double(maxDailyPoints), 1)
    }

    func completeTask(_ task: DailyTask) {
        guard let index = dailyPlan.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        dailyPlan.tasks[index].isComplete.toggle()
    }

    func requestHealthAccessPreview() {
        healthAuthorizationState = .needsSystemPrompt
    }
}
