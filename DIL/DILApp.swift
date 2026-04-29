import SwiftUI

@main
struct DILApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(appState)
        }
    }
}

private struct AppShellView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem { Label("Today", systemImage: "house.fill") }
                    .tag(AppTab.today)

                TrackView()
                    .tabItem { Label("Track", systemImage: "plus.circle.fill") }
                    .tag(AppTab.track)

                GoalsView()
                    .tabItem { Label("Goals", systemImage: "target") }
                    .tag(AppTab.goals)

                LeaderboardView()
                    .tabItem { Label("Board", systemImage: "trophy.fill") }
                    .tag(AppTab.leaderboard)

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                    .tag(AppTab.profile)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(.dilInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}

private enum AppTab: Hashable {
    case today
    case track
    case goals
    case leaderboard
    case profile
}
