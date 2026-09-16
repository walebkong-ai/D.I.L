import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { screenWidth in
                    HeaderView(eyebrow: appState.leaderboard.seasonTitle, title: "Leaderboard", systemImage: "trophy.fill")

                    if appState.leaderboard.entries.isEmpty {
                        EmptyStatePanel(
                            icon: "person.2.slash.fill",
                            title: "No friends connected",
                            detail: "Friend invitations and online rankings are not available yet. Your points this week: \(appState.user.weeklyPoints).",
                            color: .dilGold
                        )
                    }

                    Card(background: .dilGold.opacity(0.25)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Points only")
                                .font(.title2.weight(.bold))
                            Text("Your points are based on completed goals. No health data or activity is currently shared with friends.")
                                .font(.subheadline)
                                .foregroundStyle(Color.dilMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(spacing: 12) {
                        if !appState.leaderboard.entries.isEmpty {
                            SectionHeader(title: "Rankings", detail: "Points only")
                        }
                        ForEach(appState.leaderboard.entries) { entry in
                            LeaderboardRow(entry: entry, isCurrentUser: entry.name == appState.user.name, isCompact: screenWidth < 390)
                        }
                    }

                    if !appState.leaderboard.challenges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Challenges")
                            ForEach(appState.leaderboard.challenges) { challenge in
                                ChallengeCard(challenge: challenge)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }
}

private struct LeaderboardRow: View {
    var entry: LeaderboardEntry
    var isCurrentUser: Bool
    var isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 10 : 14) {
            Text("\(entry.rank)")
                .font((isCompact ? Font.headline : Font.title3).weight(.black))
                .foregroundStyle(isCurrentUser ? Color.white : Color.dilInk)
                .frame(width: isCompact ? 38 : 44, height: isCompact ? 38 : 44)
                .background(isCurrentUser ? Color.dilInk : Color.white, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                Text("\(entry.streak)-day streak · \(entry.badge)")
                    .font(.subheadline)
                    .foregroundStyle(Color.dilMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            Text("\(entry.points)")
                .font((isCompact ? Font.headline : Font.title3).weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("pts")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
        }
        .padding(isCompact ? 12 : 14)
        .background(isCurrentUser ? Color.dilGold.opacity(0.30) : .white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.dilLine, lineWidth: 1)
        )
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
