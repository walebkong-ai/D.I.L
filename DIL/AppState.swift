import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var healthMessage = "No health records imported."
    @Published var isRequestingHealth = false
    @Published var healthReadState: HealthReadState = .notRequested
    @Published var latestHealthSummary: DailyHealthSummary?
    @Published var user = UserProfile(name: "You", handle: "", city: "", weeklyPoints: 0, streakDays: 0, privacyMode: .privateOnly)
    @Published private(set) var dailyPlan = DailyPlan.initial
    @Published var leaderboard = Leaderboard(seasonTitle: "This week", entries: [], challenges: [])
    @Published var healthInsightSnapshot = HealthInsightsEngine.buildSnapshot(from: [])
    @Published var persistenceMessage: String?
    private let activityStore: any DailyActivityStore
    private let now: () -> Date
    private let calendar: Calendar
    @Published private(set) var history: [DailyActivity] = []
    private var storageReadable = true

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = { Date() }, calendar: Calendar = .autoupdatingCurrent, activityStore: (any DailyActivityStore)? = nil) {
        self.activityStore = activityStore ?? LocalDailyActivityStore(defaults: defaults, calendar: calendar)
        self.now = now
        self.calendar = calendar
        dailyPlan.date = now()
        loadCurrentDay()
    }

    private func loadCurrentDay() {
        do {
            let activity = try activityStore.loadDay(for: now()) ?? DailyActivity(date: now(), tasks: [])
            try activityStore.saveDay(activity)
            dailyPlan.date = activity.date
            dailyPlan.tasks = activity.tasks
            history = try activityStore.loadHistory()
            storageReadable = true
            persistenceMessage = nil
            recalculate()
        } catch {
            dailyPlan.date = now()
            dailyPlan.tasks = []
            history = []
            recalculate()
            storageReadable = false
            persistenceMessage = "Saved goals could not be loaded. They have not been overwritten. Please retry."
        }
    }

    func retryActivityLoad() { loadCurrentDay() }

    func refreshDay() {
        guard !calendar.isDate(dailyPlan.date, inSameDayAs: now()) else { return }
        loadCurrentDay()
        latestHealthSummary = nil
        healthInsightSnapshot = HealthInsightsEngine.buildSnapshot(from: [])
        if healthReadState != .notRequested {
            healthReadState = .noReadableData
            healthMessage = "A new day has started. Refresh Health from Profile to load today's records."
        }
    }

    func deleteActivityHistory() {
        do {
            try activityStore.deleteAll()
            loadCurrentDay()
        } catch { persistenceMessage = "Could not delete activity. Please retry." }
    }

    var activityExport: String? {
        guard let data = try? JSONEncoder().encode(history) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func addTask(title: String, detail: String, points: Int, categoryName: String, icon: String = "checkmark.circle") {
        refreshDay()
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard storageReadable, !title.isEmpty, (1...120).contains(points), dailyPlan.categories.contains(where: { $0.name == categoryName }) else { return }
        dailyPlan.tasks.append(DailyTask(title: title, detail: detail, points: points, categoryName: categoryName, icon: icon))
        recalculate()
        persist()
    }

    func updateTask(_ task: DailyTask, title: String, detail: String, points: Int, categoryName: String) {
        refreshDay()
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard storageReadable, !title.isEmpty, (1...120).contains(points), dailyPlan.categories.contains(where: { $0.name == categoryName }), let index = dailyPlan.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        dailyPlan.tasks[index].title = title
        dailyPlan.tasks[index].detail = detail
        dailyPlan.tasks[index].points = points
        dailyPlan.tasks[index].categoryName = categoryName
        recalculate()
        persist()
    }

    func deleteTasks(at offsets: IndexSet) {
        refreshDay()
        guard storageReadable, offsets.allSatisfy({ dailyPlan.tasks.indices.contains($0) }) else { return }
        dailyPlan.tasks.remove(atOffsets: offsets)
        recalculate()
        persist()
    }

    private func recalculate() {
        for index in dailyPlan.categories.indices {
            let category = dailyPlan.categories[index]
            dailyPlan.categories[index].pointsEarned = PointsCalculator.categoryTotal(tasks: dailyPlan.tasks, name: category.name, cap: category.dailyCap)
        }
        let week = calendar.dateInterval(of: .weekOfYear, for: now())
        user.weeklyPoints = history.filter { week?.contains($0.date) == true }.reduce(0) {
            $0 + PointsCalculator.dailyTotal(tasks: $1.tasks, categories: dailyPlan.categories)
        }
        var streak = 0
        var day = calendar.startOfDay(for: now())
        let todayDone = !dailyPlan.tasks.isEmpty && dailyPlan.tasks.allSatisfy(\.isComplete)
        if !todayDone { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        while let activity = history.first(where: { calendar.isDate($0.date, inSameDayAs: day) }),
              !activity.tasks.isEmpty, activity.tasks.allSatisfy(\.isComplete) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        user.streakDays = streak
    }

    private func persist() {
        guard storageReadable else { return }
        do {
            try activityStore.saveDay(DailyActivity(date: dailyPlan.date, tasks: dailyPlan.tasks))
            history = try activityStore.loadHistory()
            persistenceMessage = nil
        } catch { persistenceMessage = "Could not save goals. Please retry." }
        recalculate()
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

    func completeTask(_ task: DailyTask) {
        refreshDay()
        guard storageReadable, let index = dailyPlan.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        dailyPlan.tasks[index].isComplete.toggle()
        recalculate()
        persist()
    }

    func requestHealthAccess() async {
        guard !isRequestingHealth else { return }
        let service = HealthAccessService()
        guard service.isHealthDataAvailable else {
            healthReadState = .unavailable
            healthMessage = "Apple Health is unavailable on this device."
            return
        }
        isRequestingHealth = true
        healthReadState = .loading
        defer { isRequestingHealth = false }
        do {
            try await service.requestCoreWellnessAccess()
            let summaries = try await service.fetchRecentSummaries()
            healthInsightSnapshot = HealthInsightsEngine.buildSnapshot(from: summaries)
            latestHealthSummary = summaries.last
            let metrics = summaries.last.map { [$0.sleepMinutes, $0.steps, $0.activeEnergy, $0.restingHeartRate, $0.heartRateVariability, $0.workoutLoad].compactMap { $0 }.count } ?? 0
            healthReadState = metrics == 0 ? .noReadableData : metrics == 6 ? .ready : .partial
            healthMessage = metrics == 0 ? "No readable samples today. Access may be disabled or records may be absent; Apple does not reveal read denial. Check Health permissions and retry." : "Available Health records loaded. Missing metrics are unavailable. This does not verify Garmin sync."
        } catch {
            healthReadState = .failed
            latestHealthSummary = nil
            healthInsightSnapshot = HealthInsightsEngine.buildSnapshot(from: [])
            healthMessage = "Could not request Health access. Please try again."
        }
    }
}
