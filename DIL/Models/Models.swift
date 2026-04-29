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

    static let sample = UserProfile(
        name: "Kaleb",
        handle: "@kaleb",
        city: "Denver",
        weeklyPoints: 2610,
        streakDays: 8,
        privacyMode: .friendsOnly
    )
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

    static let sample = DailyPlan(
        date: .now,
        categories: [
            PointCategory(name: "Fitness", icon: "figure.run", color: .dilOrange, pointsEarned: 85, dailyCap: 120),
            PointCategory(name: "School", icon: "book.closed.fill", color: .dilBlue, pointsEarned: 70, dailyCap: 120),
            PointCategory(name: "Habits", icon: "checkmark.seal.fill", color: .dilGreen, pointsEarned: 60, dailyCap: 100),
            PointCategory(name: "Wellbeing", icon: "moon.zzz.fill", color: .dilPurple, pointsEarned: 35, dailyCap: 80),
            PointCategory(name: "Social", icon: "person.2.fill", color: .dilGold, pointsEarned: 10, dailyCap: 30)
        ],
        tasks: [
            DailyTask(title: "Organic chemistry review", detail: "45 minute focus block", points: 20, categoryName: "School", icon: "timer", isComplete: true),
            DailyTask(title: "Push workout", detail: "Chest, shoulders, triceps", points: 40, categoryName: "Fitness", icon: "dumbbell.fill", isComplete: false),
            DailyTask(title: "Water check-in", detail: "Log 24 oz before lunch", points: 5, categoryName: "Habits", icon: "drop.fill", isComplete: true),
            DailyTask(title: "Evening reflection", detail: "Mood, stress, and win of the day", points: 10, categoryName: "Wellbeing", icon: "pencil.and.list.clipboard", isComplete: false)
        ],
        insights: [
            Insight(title: "Today’s edge", message: "Your best study days usually happen after a short workout. Try the push session before your next focus block."),
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

struct DailyTask: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var points: Int
    var categoryName: String
    var icon: String
    var isComplete: Bool
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

    static let sample = Leaderboard(
        seasonTitle: "Week 17 Season",
        entries: [
            LeaderboardEntry(rank: 1, name: "Maya", points: 2840, streak: 12, badge: "Consistency"),
            LeaderboardEntry(rank: 2, name: "Kaleb", points: 2610, streak: 8, badge: "Comeback"),
            LeaderboardEntry(rank: 3, name: "Jordan", points: 2420, streak: 6, badge: "Study Sprint"),
            LeaderboardEntry(rank: 4, name: "Alex", points: 2105, streak: 4, badge: "Hydrated")
        ],
        challenges: [
            Challenge(title: "Finals Focus", detail: "Log 5 study blocks this week", reward: 120, progress: 0.6),
            Challenge(title: "Balanced Day", detail: "Earn points in 4 categories", reward: 75, progress: 0.8)
        ]
    )
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
