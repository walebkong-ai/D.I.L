import Foundation

struct DailyActivity: Codable {
    var date: Date
    var tasks: [DailyTask]
}

protocol DailyActivityStore {
    func loadDay(for date: Date) throws -> DailyActivity?
    func saveDay(_ activity: DailyActivity) throws
    func loadHistory() throws -> [DailyActivity]
    func deleteAll() throws
}

enum ActivityStoreError: Error { case invalidData }

final class LocalDailyActivityStore: DailyActivityStore {
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let key = "goodMorning.dailyHistory.v2"
    private let legacyKey = "goodMorning.dailyPlan.v1"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
    }

    private func dateKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    private func records() throws -> [String: DailyActivity] {
        if defaults.object(forKey: key) != nil && defaults.data(forKey: key) == nil { throw ActivityStoreError.invalidData }
        if defaults.object(forKey: key) == nil && defaults.object(forKey: legacyKey) != nil && defaults.data(forKey: legacyKey) == nil { throw ActivityStoreError.invalidData }
        if let data = defaults.data(forKey: key) {
            let records = try JSONDecoder().decode([String: DailyActivity].self, from: data)
            try records.values.forEach(validate)
            return records
        }
        guard let data = defaults.data(forKey: legacyKey) else { return [:] }
        let old = try JSONDecoder().decode(LegacyPlan.self, from: data)
        var result: [String: DailyActivity] = [:]
        func insert(_ plan: LegacyPlan) throws {
            for child in plan.history ?? [] { try insert(child) }
            let activity = DailyActivity(date: plan.date, tasks: plan.tasks)
            try validate(activity)
            result[dateKey(plan.date)] = activity
        }
        try insert(old)
        defaults.set(try JSONEncoder().encode(result), forKey: key)
        defaults.removeObject(forKey: legacyKey)
        return result
    }

    private func validate(_ activity: DailyActivity) throws {
        guard activity.date.timeIntervalSince1970.isFinite,
              Set(activity.tasks.map(\.id)).count == activity.tasks.count,
              activity.tasks.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (1...120).contains($0.points) && ["Fitness", "School", "Habits", "Wellbeing", "Social"].contains($0.categoryName) }) else { throw ActivityStoreError.invalidData }
    }

    func loadDay(for date: Date) throws -> DailyActivity? { try records()[dateKey(date)] }
    func loadHistory() throws -> [DailyActivity] { try records().values.sorted { $0.date < $1.date } }
    func saveDay(_ activity: DailyActivity) throws {
        try validate(activity)
        var records = try records()
        records[dateKey(activity.date)] = activity
        defaults.set(try JSONEncoder().encode(records), forKey: key)
    }
    func deleteAll() throws {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }
    private struct LegacyPlan: Codable {
        var date: Date
        var tasks: [DailyTask]
        var history: [LegacyPlan]?
    }
}

enum PointsCalculator {
    static func categoryTotal(tasks: [DailyTask], name: String, cap: Int) -> Int {
        // Saturate during addition so malformed or very large lists cannot overflow.
        tasks.filter { $0.isComplete && $0.categoryName == name }.reduce(0) { total, task in
            total + min(max(0, task.points), max(0, cap - total))
        }
    }
    static func dailyTotal(tasks: [DailyTask], categories: [PointCategory]) -> Int {
        categories.reduce(0) { $0 + categoryTotal(tasks: tasks, name: $1.name, cap: $1.dailyCap) }
    }
}
