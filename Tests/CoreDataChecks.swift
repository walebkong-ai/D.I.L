import Foundation

// Standalone checks compile against the production sources without a new Xcode target.
@main
struct CoreDataChecks {
    @MainActor static func main() throws {
        let suite = "GoodMorningCoreChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var clock = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 12))!
        let store = LocalDailyActivityStore(defaults: defaults, calendar: calendar)
        let state = AppState(defaults: defaults, now: { clock }, calendar: calendar, activityStore: store)
        var count = 0
        func check(_ condition: Bool, _ name: String) {
            precondition(condition, name)
            count += 1
            print("PASS \(name)")
        }
        check(state.dailyPointTotal == 0 && state.dailyPlan.tasks.isEmpty, "fresh install")
        state.addTask(title: "Workout A", detail: "", points: 80, categoryName: "Fitness")
        let firstID = state.dailyPlan.tasks[0].id
        state.completeTask(state.dailyPlan.tasks[0])
        check(state.dailyPointTotal == 80, "complete")
        state.completeTask(state.dailyPlan.tasks[0])
        check(state.dailyPointTotal == 0, "uncomplete")
        state.completeTask(state.dailyPlan.tasks[0])
        check(state.dailyPlan.categories.first { $0.name == "School" }!.pointsEarned == 0, "correct category")
        state.addTask(title: "Workout B", detail: "", points: 70, categoryName: "Fitness")
        state.completeTask(state.dailyPlan.tasks[1])
        check(state.dailyPointTotal == 120, "cap 150 at 120")
        state.addTask(title: "Study", detail: "", points: 20, categoryName: "School")
        state.completeTask(state.dailyPlan.tasks[2])
        check(state.dailyPointTotal == 140 && state.dailyPointTotal == state.dailyPlan.categories.reduce(0) { $0 + $1.pointsEarned }, "daily total")
        let restored = AppState(defaults: defaults, now: { clock }, calendar: calendar, activityStore: store)
        check(restored.dailyPlan.tasks[0].isComplete && restored.dailyPlan.tasks[0].id == firstID && restored.dailyPointTotal == 140, "reload stable IDs and completion")
        restored.updateTask(restored.dailyPlan.tasks[0], title: "Workout A", detail: "", points: 10, categoryName: "Fitness")
        check(restored.dailyPointTotal == 100, "edit completed task")
        restored.deleteTasks(at: IndexSet(integer: 1))
        check(restored.dailyPointTotal == 30, "delete completed task")
        let yesterday = clock
        clock = calendar.date(byAdding: .day, value: 1, to: clock)!
        restored.refreshDay()
        check(try store.loadDay(for: yesterday)?.tasks.count == 2, "preserve yesterday")
        check(restored.dailyPlan.tasks.isEmpty && restored.dailyPointTotal == 0 && calendar.isDate(restored.dailyPlan.date, inSameDayAs: clock), "rollover")
        _ = AppState(defaults: defaults, now: { clock }, calendar: calendar, activityStore: store)
        _ = AppState(defaults: defaults, now: { clock }, calendar: calendar, activityStore: store)
        check(try store.loadHistory().count == 2, "no duplicate days")
        defaults.set(Data("invalid".utf8), forKey: "goodMorning.dailyHistory.v2")
        let corrupt = AppState(defaults: defaults, now: { clock }, calendar: calendar, activityStore: store)
        corrupt.addTask(title: "Do not overwrite", detail: "", points: 10, categoryName: "Habits")
        check(corrupt.persistenceMessage != nil && defaults.data(forKey: "goodMorning.dailyHistory.v2") == Data("invalid".utf8), "corruption safe")
        check(corrupt.healthReadState == .notRequested && corrupt.healthInsightSnapshot.sleepScore == nil && corrupt.healthInsightSnapshot.recoveryScore == nil, "no permission no score")
        let empty = HealthInsightsEngine.buildSnapshot(from: [])
        check(empty.sleepScore == nil && empty.recoveryScore == nil, "no samples distinct from zero")
        let noSamples = DailyHealthSummary(date: clock, provider: .appleHealth, sourceDevice: "Health", sleepMinutes: nil, sleepEfficiency: nil, bedtimeMinutes: nil, wakeMinutes: nil, restingHeartRate: nil, heartRateVariability: nil, respiratoryRate: nil, temperatureDeviation: nil, steps: nil, activeEnergy: nil, workoutLoad: nil)
        let noSamplesScore = HealthInsightsEngine.buildSnapshot(from: [noSamples])
        check(noSamplesScore.sleepScore == nil && noSamplesScore.recoveryScore == nil, "permission finished but no samples")
        var partial = noSamples
        partial.steps = 0
        let partialScore = HealthInsightsEngine.buildSnapshot(from: [partial])
        check(partialScore.activityLabel == "0 steps" && partialScore.sleepScore == nil, "recorded zero and partial data")
        var realHistory: [DailyHealthSummary] = []
        for offset in (-5)...0 {
            var summary = noSamples
            summary.date = calendar.date(byAdding: .day, value: offset, to: clock)!
            summary.sleepMinutes = 450
            realHistory.append(summary)
        }
        let sleepOnly = HealthInsightsEngine.buildSnapshot(from: realHistory)
        check(sleepOnly.sleepScore == 100 && sleepOnly.recoveryScore == nil, "duration score requires real history; missing recovery stays nil")
        for index in realHistory.indices {
            realHistory[index].restingHeartRate = 60
            realHistory[index].heartRateVariability = 50
        }
        check(HealthInsightsEngine.buildSnapshot(from: realHistory).recoveryScore == 100, "recovery requires real sleep HRV and RHR baselines")
        try store.deleteAll()
        clock = yesterday
        let returned = AppState(defaults: defaults, now: { clock }, calendar: calendar, activityStore: store)
        returned.addTask(title: "Travel", detail: "", points: 10, categoryName: "Habits")
        clock = calendar.date(byAdding: .day, value: 1, to: clock)!
        returned.refreshDay()
        clock = yesterday
        returned.refreshDay()
        check(returned.dailyPlan.tasks.count == 1, "clock moves back to saved day")
        let legacy = DailyActivity(date: clock, tasks: returned.dailyPlan.tasks)
        try store.deleteAll()
        defaults.set(try JSONEncoder().encode(legacy), forKey: "goodMorning.dailyPlan.v1")
        check(try store.loadDay(for: clock)?.tasks.first?.id == legacy.tasks.first?.id, "v1 migration")
        print("\(count) checks passed")
    }
}
