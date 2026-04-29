import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScreenBackground {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let metrics = ProfileMetrics(width: width, height: height)

                    ProfileFullHeightContent(
                        userHandle: appState.user.handle,
                        userName: appState.user.name,
                        weeklyPoints: appState.user.weeklyPoints,
                        streakDays: appState.user.streakDays,
                        sharingMode: appState.user.privacyMode.rawValue,
                        healthAuthorizationState: appState.healthAuthorizationState,
                        metrics: metrics,
                        onPrepareHealth: appState.requestHealthAccessPreview
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct ProfileMetrics {
    let width: CGFloat
    let height: CGFloat

    var horizontalPadding: CGFloat { width * 0.052 }
    var contentWidth: CGFloat { min(width - horizontalPadding * 2, 480) }
    var sectionSpacer: CGFloat { height * 0.018 }
    var outerSpacer: CGFloat { height * 0.02 }
    var rowGap: CGFloat { width * 0.03 }
    var cardPadding: CGFloat { width * 0.048 }
    var cornerRadius: CGFloat { Fluid.clamp(width * 0.058, min: 20, max: 28) }
    var profileIconSize: CGFloat { Fluid.clamp(width * 0.16, min: 54, max: 76) }
    var eyebrowFont: CGFloat { Fluid.clamp(width * 0.052, min: 18, max: 24) }
    var nameFont: CGFloat { Fluid.clamp(width * 0.12, min: 42, max: 62) }
    var statTitleFont: CGFloat { Fluid.clamp(width * 0.044, min: 15, max: 20) }
    var statValueFont: CGFloat { Fluid.clamp(width * 0.066, min: 24, max: 34) }
    var statUnitFont: CGFloat { Fluid.clamp(width * 0.04, min: 14, max: 18) }
    var cardTitleFont: CGFloat { Fluid.clamp(width * 0.068, min: 25, max: 34) }
    var bodyFont: CGFloat { Fluid.clamp(width * 0.044, min: 16, max: 21) }
    var dividerVerticalPadding: CGFloat { height * 0.006 }
}

private struct ProfileFullHeightContent: View {
    var userHandle: String
    var userName: String
    var weeklyPoints: Int
    var streakDays: Int
    var sharingMode: String
    var healthAuthorizationState: HealthAuthorizationState
    var metrics: ProfileMetrics
    var onPrepareHealth: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: metrics.outerSpacer)

            ProfileIdentityView(
                eyebrow: userHandle,
                name: userName,
                iconSize: metrics.profileIconSize,
                eyebrowSize: metrics.eyebrowFont,
                nameSize: metrics.nameFont
            )

            Spacer(minLength: metrics.sectionSpacer)

            Card(padding: metrics.cardPadding, cornerRadius: metrics.cornerRadius) {
                HStack(spacing: 0) {
                    ProfileStat(title: "Weekly", value: "\(weeklyPoints)", unit: "pts", metrics: metrics)
                    Divider().padding(.vertical, metrics.dividerVerticalPadding)
                    ProfileStat(title: "Streak", value: "\(streakDays)", unit: "days", metrics: metrics)
                    Divider().padding(.vertical, metrics.dividerVerticalPadding)
                    ProfileStat(title: "Sharing", value: sharingMode, unit: "", metrics: metrics)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: metrics.sectionSpacer)

            Card(padding: metrics.cardPadding, cornerRadius: metrics.cornerRadius) {
                VStack(alignment: .leading, spacing: metrics.rowGap) {
                    Text("Privacy & App Store Readiness")
                        .font(.system(size: metrics.cardTitleFont, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    ComplianceRow(icon: "lock.shield.fill", text: "Health, mood, grades, journal, and body metrics are private by default.", metrics: metrics)
                    ComplianceRow(icon: "person.crop.circle.badge.checkmark", text: "Friends leaderboard uses points only.", metrics: metrics)
                    ComplianceRow(icon: "heart.text.square.fill", text: "Apple Health access is requested only when a feature needs it.", metrics: metrics)
                    ComplianceRow(icon: "trash.fill", text: "Account deletion and data export need to be added before public launch.", metrics: metrics)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .layoutPriority(1)

            Spacer(minLength: metrics.sectionSpacer)

            Button(action: onPrepareHealth) {
                HStack(spacing: metrics.rowGap) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: metrics.bodyFont, weight: .bold))
                    Text("Prepare Apple Health Connection")
                        .font(.system(size: metrics.bodyFont, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Spacer(minLength: metrics.rowGap)
                    Image(systemName: "chevron.right")
                        .font(.system(size: metrics.bodyFont, weight: .semibold))
                }
                .padding(metrics.cardPadding)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(Color.dilInk, in: RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if healthAuthorizationState == .needsSystemPrompt {
                Spacer(minLength: metrics.sectionSpacer)
                Card(background: .dilPurple.opacity(0.18), padding: metrics.cardPadding, cornerRadius: metrics.cornerRadius) {
                    Text("Next implementation step: show Apple’s system permission sheet from the exact feature requesting steps, workouts, sleep, or heart rate.")
                        .font(.system(size: metrics.bodyFont, weight: .medium))
                        .foregroundStyle(Color.dilInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: metrics.outerSpacer)
        }
        .frame(width: metrics.contentWidth)
        .padding(.horizontal, metrics.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ProfileIdentityView: View {
    var eyebrow: String
    var name: String
    var iconSize: CGFloat
    var eyebrowSize: CGFloat
    var nameSize: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: Fluid.clamp(iconSize * 0.32, min: 14, max: 22)) {
            Circle()
                .fill(Color.dilInk)
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: iconSize * 0.42, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow)
                    .font(.system(size: eyebrowSize, weight: .semibold))
                    .foregroundStyle(Color.dilMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(name)
                    .font(.system(size: nameSize, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dilInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileStat: View {
    var title: String
    var value: String
    var unit: String
    var metrics: ProfileMetrics

    var body: some View {
        VStack(spacing: Fluid.clamp(metrics.height * 0.004, min: 3, max: 6)) {
            Text(title)
                .font(.system(size: metrics.statTitleFont, weight: .semibold))
                .foregroundStyle(Color.dilMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.system(size: metrics.statValueFont, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.64)
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: metrics.statUnitFont, weight: .semibold))
                    .foregroundStyle(Color.dilMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ComplianceRow: View {
    var icon: String
    var text: String
    var metrics: ProfileMetrics

    var body: some View {
        HStack(alignment: .top, spacing: metrics.rowGap) {
            Image(systemName: icon)
                .foregroundStyle(Color.dilGreen)
                .font(.system(size: metrics.bodyFont, weight: .bold))
                .frame(width: metrics.bodyFont * 1.7)
            Text(text)
                .font(.system(size: metrics.bodyFont))
                .foregroundStyle(Color.dilMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
