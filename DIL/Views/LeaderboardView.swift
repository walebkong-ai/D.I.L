import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { screenWidth in
                    HeaderView(eyebrow: appState.leaderboard.seasonTitle, title: "Leaderboard", systemImage: "trophy.fill")
                    MetricSummaryCard(title: "Your week", status: "\(appState.user.weeklyPoints) pts",
                                      value: appState.leaderboard.entries.first(where: { $0.name == appState.user.name }).map { "Rank \($0.rank)" } ?? "Not ranked")
                    Text("Leaderboard sharing is off").font(.subheadline).foregroundStyle(Color.dilMuted)

                    if appState.leaderboard.entries.isEmpty {
                        EmptyStatePanel(
                            icon: "person.2.slash.fill",
                            title: "No friends yet",
                            detail: "Friend invitations and online rankings aren't available yet.",
                            color: .dilGold
                        )
                    }

                    VStack(spacing: 12) {
                        if !appState.leaderboard.entries.isEmpty {
                            SectionHeader(title: "Rankings", detail: "Points only")
                        }
                        ForEach(appState.leaderboard.entries) { entry in
                            NavigationLink {
                                List {
                                    MetricRow(title: "Rank", value: "\(entry.rank)")
                                    MetricRow(title: "Weekly points", value: "\(entry.points) pts")
                                    MetricRow(title: "Streak", value: "\(entry.streak) days")
                                    if !entry.badge.isEmpty { Text(entry.badge) }
                                }.navigationTitle(entry.name)
                            } label: {
                                DetailDisclosure(title: "\(entry.rank). \(entry.name)", value: "\(entry.points) pts")
                            }.buttonStyle(.plain)
                        }
                    }

                    if !appState.leaderboard.challenges.isEmpty {
                        DisclosureGroup("Challenges") {
                            SectionHeader(title: "Challenges")
                            ForEach(appState.leaderboard.challenges) { challenge in
                                NavigationLink {
                                    List { Text(challenge.detail); MetricRow(title: "Reward", value: "\(challenge.reward) pts"); ProgressBar(progress: challenge.progress, color: .dilAccent) }
                                        .navigationTitle(challenge.title)
                                } label: { DetailDisclosure(title: challenge.title, value: "\(Int(challenge.progress * 100))% complete") }.buttonStyle(.plain)
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
