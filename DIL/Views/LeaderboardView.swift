import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        HeaderView(eyebrow: appState.leaderboard.seasonTitle, title: "Leaderboard", systemImage: "trophy.fill")

                        Card(background: .dilGold.opacity(0.25)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Points only")
                                    .font(.title2.weight(.bold))
                                Text("Friends see total points, streaks, and badges. Private health, grades, mood, journal, and body metrics are never shown by default.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.dilMuted)
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(appState.leaderboard.entries) { entry in
                                LeaderboardRow(entry: entry, isCurrentUser: entry.name == appState.user.name)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Challenges")
                                .font(.title2.weight(.bold))
                            ForEach(appState.leaderboard.challenges) { challenge in
                                ChallengeCard(challenge: challenge)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

private struct LeaderboardRow: View {
    var entry: LeaderboardEntry
    var isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(entry.rank)")
                .font(.title3.weight(.black))
                .foregroundStyle(isCurrentUser ? Color.white : Color.dilInk)
                .frame(width: 44, height: 44)
                .background(isCurrentUser ? Color.dilInk : Color.white, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline.weight(.bold))
                Text("\(entry.streak)-day streak · \(entry.badge)")
                    .font(.subheadline)
                    .foregroundStyle(Color.dilMuted)
            }

            Spacer()

            Text("\(entry.points)")
                .font(.title3.weight(.black))
            Text("pts")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
        }
        .padding(14)
        .background(isCurrentUser ? Color.dilGold.opacity(0.30) : .white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ChallengeCard: View {
    var challenge: Challenge

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title).font(.headline.weight(.bold))
                        Text(challenge.detail).font(.subheadline).foregroundStyle(Color.dilMuted)
                    }
                    Spacer()
                    Text("+\(challenge.reward)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.dilOrange)
                }
                ProgressBar(progress: challenge.progress, color: .dilOrange)
            }
        }
    }
}
