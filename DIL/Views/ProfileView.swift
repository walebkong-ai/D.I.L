import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirmActivityDeletion = false

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    HeaderView(eyebrow: "Your space", title: "Profile", systemImage: "person.crop.circle.fill")

                    ProfileHeroCard(user: appState.user)

                    NavigationLink {
                        ScreenBackground {
                            AdaptiveScreen { _ in
                                HealthConnectionCard(
                                    state: appState.healthReadState,
                                    message: appState.healthMessage,
                                    isRequesting: appState.isRequestingHealth
                                ) {
                                    Task { await appState.requestHealthAccess() }
                                }
                    GarminSetupCard()
                    #if DEBUG
                    NavigationLink("Health diagnostics") { HealthDiagnosticsView() }
                    #endif
                            }
                        }.navigationTitle("Health connection").navigationBarTitleDisplayMode(.inline)
                    } label: {
                        DetailDisclosure(title: "Apple Health", value: healthStatus)
                    }.buttonStyle(.plain)
                    NavigationLink {
                        ScreenBackground {
                            AdaptiveScreen { _ in
                                PrivacyCard(
                                    weeklyPoints: appState.user.weeklyPoints,
                                    activityExport: appState.activityExport,
                                    onDeleteActivity: { confirmActivityDeletion = true }
                                )
                            }
                        }.navigationTitle("Privacy and data").navigationBarTitleDisplayMode(.inline)
                    } label: {
                        DetailDisclosure(title: "Privacy and data", value: "Stored on this device · Sharing off")
                    }.buttonStyle(.plain)
                    NavigationLink("View daily history") { GoalHistoryView() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Delete all daily goals and history? This cannot be undone. Health records are unchanged.", isPresented: $confirmActivityDeletion, titleVisibility: .visible) {
                Button("Delete activity", role: .destructive) { appState.deleteActivityHistory() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }

    private var healthStatus: String {
        switch appState.healthReadState {
        case .ready: "Records loaded"
        case .partial: "Some records loaded"
        case .loading: "Loading"
        case .failed: "Needs a retry"
        case .unavailable: "Unavailable"
        case .noReadableData: "No readable records"
        case .notRequested: "Not connected"
        }
    }
}

private struct ProfileHeroCard: View {
    var user: UserProfile

    var body: some View {
        Card(background: Color.dilHero) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.dilGold)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(initials)
                            .font(.title.weight(.black))
                            .foregroundStyle(Color.dilHero)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(user.name)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(profileDetail.isEmpty ? "Local profile" : profileDetail)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var initials: String {
        let parts = user.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        return letters.isEmpty ? "GM" : String(letters).uppercased()
    }

    private var profileDetail: String {
        [user.handle.isEmpty ? nil : user.handle, user.city.isEmpty ? nil : user.city]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

private struct HealthConnectionCard: View {
    var state: HealthReadState
    var message: String
    var isRequesting: Bool
    var onRequest: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    AdaptiveIconTile(color: .dilPurple, icon: "heart.text.square.fill", size: 54)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Apple Health")
                            .font(.title3.weight(.black))
                            .foregroundStyle(Color.dilInk)
                        Text("Optional sleep, activity, and recovery inputs.")
                            .font(.subheadline)
                            .foregroundStyle(Color.dilMuted)
                    }
                    Spacer(minLength: 0)
                    StatusBadge(text: statusText, color: statusColor, icon: statusIcon)
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.dilMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onRequest) {
                    HStack {
                        Image(systemName: isRequesting ? "hourglass" : "heart.fill")
                            .font(.headline.weight(.black))
                        Text(isRequesting ? "Loading…" : state == .notRequested ? "Connect Apple Health" : "Refresh Health records")
                            .font(.headline.weight(.black))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.dilHero, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isRequesting)
                .opacity(isRequesting ? 0.72 : 1)
                if isRequesting { ProgressView("Loading Health records") }
            }
        }
    }

    private var statusText: String {
        switch state {
        case .notRequested: "Not connected"
        case .unavailable: "Unavailable"
        case .loading: "Loading"
        case .noReadableData: "No data"
        case .partial: "Partial"
        case .ready: "Ready"
        case .failed: "Retry"
        }
    }

    private var statusColor: Color {
        switch state {
        case .ready: .dilGreen
        case .partial, .loading: .dilGold
        case .failed, .unavailable: .dilOrange
        case .notRequested, .noReadableData: .dilMuted
        }
    }

    private var statusIcon: String {
        switch state {
        case .ready: "checkmark"
        case .partial, .loading: "clock.fill"
        case .failed, .unavailable: "exclamationmark"
        case .notRequested, .noReadableData: "minus"
        }
    }
}

private struct GarminSetupCard: View {

    var body: some View {
        Card(background: Color.dilGreen.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    AdaptiveIconTile(color: .dilGreen, icon: "figure.run", size: 54)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Garmin via Apple Health")
                            .font(.title3.weight(.black))
                            .foregroundStyle(Color.dilInk)
                        Text("Sync through Garmin Connect into Apple Health.")
                            .font(.subheadline)
                            .foregroundStyle(Color.dilMuted)
                    }
                    Spacer(minLength: 0)
                    StatusBadge(text: "Via Health", color: .dilGreen)
                }

                VStack(alignment: .leading, spacing: 9) {
                    SetupStep(icon: "1.circle.fill", text: "Pair the watch in Garmin Connect.")
                    SetupStep(icon: "2.circle.fill", text: "Enable Apple Health sharing in Garmin Connect.")
                    SetupStep(icon: "3.circle.fill", text: "Approve the Health categories Good Morning asks for.")
                    Text("Not a direct watch connection. Available fields depend on Garmin Connect; HRV and other metrics may not sync.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SetupStep: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color.dilGreen)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.dilInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PrivacyCard: View {
    var weeklyPoints: Int
    var activityExport: String?
    var onDeleteActivity: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    SectionHeader(title: "Privacy")
                    Spacer()
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.dilMuted)
                    }
                    .accessibilityLabel("Privacy policy")
                    .frame(minWidth: 44, minHeight: 44)
                }

                PrivacyRow(icon: "lock.shield.fill", text: "No account or cloud sharing is enabled.")
                PrivacyRow(icon: "person.2.slash.fill", text: "Online friend rankings are not available yet.")
                PrivacyRow(icon: "trophy.fill", text: "Only your weekly point total is shown here: \(weeklyPoints).")

                VStack(alignment: .leading, spacing: 12) {
                    if let activityExport {
                        ShareLink(item: activityExport) {
                            Label("Export activity", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.black))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.dilInk)
                    }

                    Spacer()

                    Button(role: .destructive, action: onDeleteActivity) {
                        Label("Delete history", systemImage: "trash")
                            .font(.subheadline.weight(.black))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
    }
}

private struct PrivacyRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.dilInk)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.dilMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section("Local logs") {
                Text("Daily goals, completion state, and past daily plans are stored in this app's UserDefaults on your device to calculate daily and weekly points. Export or delete daily history in Profile. System device backup may include these records.")
                Text("Your log category, note, and date are stored in a protected file on this device, excluded from backup. They remain until you delete logs or uninstall the app. Export sends a copy only to the destination you choose.")
            }
            Section("Health") {
                Text("Apple Health permissions are requested only when you tap the connection button. Available sleep, steps, energy, workouts, resting heart rate and HRV records are read into memory for display and optional wellness indices. They are not saved to disk or transmitted. Garmin is a possible upstream source, not a direct connection. Revoke permissions in Health.")
            }
            Section("Sharing") {
                Text("The native app has no accounts, advertising, tracking, analytics SDKs, or external AI calls. Logs are not shared with friends or sent to us. Delete and export local logs from Track.")
            }
        }.navigationTitle("Privacy policy")
    }
}
