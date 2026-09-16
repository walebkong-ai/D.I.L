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
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today

    var body: some View {
        ZStack {
            Color.dilBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem { Label("Today", systemImage: "house.fill") }
                    .tag(AppTab.today)

                LocalLogsView()
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
            .background(Color.dilBackground.ignoresSafeArea())
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(.dilInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appState.refreshDay() }
        }
        .task {
            while !Task.isCancelled {
                if scenePhase == .active { appState.refreshDay() }
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }
}

private enum AppTab: Hashable {
    case today
    case track
    case goals
    case leaderboard
    case profile
}
