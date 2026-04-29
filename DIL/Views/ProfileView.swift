import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { screenWidth in
                    HeaderView(eyebrow: appState.user.handle, title: appState.user.name, systemImage: "person.fill")

                    Card {
                        HStack {
                            ProfileStat(title: "Weekly", value: "\(appState.user.weeklyPoints)", unit: "pts")
                            Divider()
                            ProfileStat(title: "Streak", value: "\(appState.user.streakDays)", unit: "days")
                            Divider()
                            ProfileStat(title: "Sharing", value: appState.user.privacyMode.rawValue, unit: "")
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Privacy & App Store Readiness")
                                .font(.title3.weight(.bold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                            ComplianceRow(icon: "lock.shield.fill", text: "Health, mood, grades, journal, and body metrics are private by default.")
                            ComplianceRow(icon: "person.crop.circle.badge.checkmark", text: "Friends leaderboard uses points only.")
                            ComplianceRow(icon: "heart.text.square.fill", text: "Apple Health access is requested only when a feature needs it.")
                            ComplianceRow(icon: "trash.fill", text: "Account deletion and data export need to be added before public launch.")
                        }
                    }

                    Button {
                        appState.requestHealthAccessPreview()
                    } label: {
                        HStack(spacing: screenWidth < 390 ? 10 : 14) {
                            Image(systemName: "heart.fill")
                            Text("Prepare Apple Health Connection")
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .padding(screenWidth < 390 ? 16 : 18)
                        .foregroundStyle(.white)
                        .background(Color.dilInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if appState.healthAuthorizationState == .needsSystemPrompt {
                        Card(background: .dilPurple.opacity(0.18)) {
                            Text("Next implementation step: show Apple’s system permission sheet from the exact feature requesting steps, workouts, sleep, or heart rate.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.dilInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

private struct ProfileStat: View {
    var title: String
    var value: String
    var unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dilMuted)
            Text(value)
                .font(.title3.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dilMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ComplianceRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.dilGreen)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.dilMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
