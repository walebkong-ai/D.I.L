import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var user = UserProfile.sample
    @Published var dailyPlan: DailyPlan {
        didSet {
            persistDailyPlan()
        }
    }
    @Published var leaderboard = Leaderboard.sample
    @Published var healthAuthorizationState: HealthAuthorizationState = .notRequested
    @Published var garminConnectionState: GarminConnectionState = .notConnected
    @Published var healthInsightSnapshot = HealthInsightsEngine.makePreviewSnapshot()

    private let defaults: UserDefaults
    private let dailyPlanKey = "goodMorning.dailyPlan.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.dailyPlan = DailyPlan.initial
        restoreDailyPlan()
        recalculateCategoryPoints()
    }

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

    func addTask(title: String, detail: String, points: Int, categoryName: String, icon: String = "checkmark.circle") {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, points > 0 else { return }

        dailyPlan.tasks.append(
            DailyTask(
                title: trimmedTitle,
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                points: points,
                categoryName: categoryName,
                icon: icon
            )
        )
        recalculateCategoryPoints()
    }

    func updateTask(_ task: DailyTask, title: String, detail: String, points: Int, categoryName: String) {
        guard let index = dailyPlan.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, points > 0 else { return }

        dailyPlan.tasks[index].title = trimmedTitle
        dailyPlan.tasks[index].detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        dailyPlan.tasks[index].points = points
        dailyPlan.tasks[index].categoryName = categoryName
        recalculateCategoryPoints()
    }

    func deleteTasks(at offsets: IndexSet) {
        dailyPlan.tasks.remove(atOffsets: offsets)
        recalculateCategoryPoints()
    }

    func completeTask(_ task: DailyTask) {
        guard let index = dailyPlan.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        dailyPlan.tasks[index].isComplete.toggle()
        recalculateCategoryPoints()
    }

    func requestHealthAccessPreview() {
        healthAuthorizationState = .needsSystemPrompt
    }

    func prepareGarminConnectionPreview() {
        garminConnectionState = .setupReady
        healthAuthorizationState = .needsSystemPrompt
    }

    func markGarminConnectedPreview() {
        garminConnectionState = .connected
        healthAuthorizationState = .authorized
    }

    private func recalculateCategoryPoints() {
        for index in dailyPlan.categories.indices {
            let categoryName = dailyPlan.categories[index].name
            let earned = dailyPlan.tasks
                .filter { $0.isComplete && $0.categoryName == categoryName }
                .reduce(0) { $0 + $1.points }
            dailyPlan.categories[index].pointsEarned = min(earned, dailyPlan.categories[index].dailyCap)
        }
    }

    private func restoreDailyPlan() {
        guard
            let data = defaults.data(forKey: dailyPlanKey),
            let stored = try? JSONDecoder().decode(StoredDailyPlan.self, from: data)
        else { return }

        dailyPlan.date = stored.date
        dailyPlan.tasks = stored.tasks
    }

    private func persistDailyPlan() {
        let stored = StoredDailyPlan(date: dailyPlan.date, tasks: dailyPlan.tasks)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        defaults.set(data, forKey: dailyPlanKey)
    }
}

private struct StoredDailyPlan: Codable {
    var date: Date
    var tasks: [DailyTask]
}
