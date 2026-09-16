import Foundation

// This payload deliberately excludes tasks, notes, grades, mood, and health data.
struct ShareableLeaderboardEntry: Codable {
    let userID: String
    let displayName: String
    let weeklyPoints: Int
    let rank: Int
    let streak: Int
    let badges: [String]
    let sharingEnabled: Bool
}

protocol LeaderboardService {
    func fetchLeaderboard() async throws -> [ShareableLeaderboardEntry]
}

struct UnconnectedLeaderboardService: LeaderboardService {
    func fetchLeaderboard() async throws -> [ShareableLeaderboardEntry] { [] }
}
