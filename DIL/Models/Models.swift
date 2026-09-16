import Foundation
import SwiftUI

struct UserProfile: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var handle: String
    var city: String
    var weeklyPoints: Int
    var streakDays: Int
    var privacyMode: PrivacyMode

}

enum PrivacyMode: String, CaseIterable, Identifiable {
    case privateOnly = "Private"
    case friendsOnly = "Friends"
    case challengeOnly = "Challenges"

    var id: String { rawValue }
}

struct DailyPlan {
    var date: Date
    var categories: [PointCategory]
    var tasks: [DailyTask]
    var insights: [Insight]

    static let initial = DailyPlan(
        date: .now,
        categories: [
            PointCategory(name: "Fitness", icon: "figure.run", color: .dilOrange, pointsEarned: 0, dailyCap: 120),
            PointCategory(name: "School", icon: "book.closed.fill", color: .dilBlue, pointsEarned: 0, dailyCap: 120),
            PointCategory(name: "Habits", icon: "checkmark.seal.fill", color: .dilGreen, pointsEarned: 0, dailyCap: 100),
            PointCategory(name: "Wellbeing", icon: "moon.zzz.fill", color: .dilPurple, pointsEarned: 0, dailyCap: 80),
            PointCategory(name: "Social", icon: "person.2.fill", color: .dilGold, pointsEarned: 0, dailyCap: 30)
        ],
        tasks: [],
        insights: [
            Insight(title: "Build your day", message: "Add daily goals, complete them as you go, and your score will update from the work you actually finish."),
            Insight(title: "Privacy note", message: "Friends only see points, rank, streak, and badges. Health, grades, mood, and journals stay private.")
        ]
    )
}

struct PointCategory: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String
    var color: Color
    var pointsEarned: Int
    var dailyCap: Int

    var progress: Double {
        guard dailyCap > 0 else { return 0 }
        return min(Double(pointsEarned) / Double(dailyCap), 1)
    }
}

struct DailyTask: Identifiable, Hashable, Codable {
    var id: UUID
    var title: String
    var detail: String
    var points: Int
    var categoryName: String
    var icon: String
    var isComplete: Bool

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        points: Int,
        categoryName: String,
        icon: String,
        isComplete: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.points = points
        self.categoryName = categoryName
        self.icon = icon
        self.isComplete = isComplete
    }
}

struct Insight: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var message: String
}

struct Leaderboard {
    var seasonTitle: String
    var entries: [LeaderboardEntry]
    var challenges: [Challenge]

}

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    var rank: Int
    var name: String
    var points: Int
    var streak: Int
    var badge: String
}

struct Challenge: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var reward: Int
    var progress: Double
}

enum HealthAuthorizationState: String {
    case notRequested
    case needsSystemPrompt
    case authorized
    case denied
}

enum GarminConnectionState: String {
    case notConnected
    case setupReady
    case connected

    var statusText: String {
        switch self {
        case .notConnected:
            "Not connected"
        case .setupReady:
            "Ready to sync"
        case .connected:
            "Connected"
        }
    }
}
