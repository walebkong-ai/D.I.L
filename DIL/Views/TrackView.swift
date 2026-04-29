import SwiftUI

struct TrackView: View {
    private let sections: [(String, String, Color, String)] = [
        ("Workout", "Exercises, sets, reps, rest", .dilOrange, "dumbbell.fill"),
        ("Study", "Subject timer and grade notes", .dilBlue, "book.closed.fill"),
        ("Habits", "Binary and measured routines", .dilGreen, "checkmark.seal.fill"),
        ("Mood", "Energy, stress, reflection", .dilPurple, "face.smiling"),
        ("Nutrition", "Meals, water, calories", .dilGold, "fork.knife"),
        ("Budget", "Student spending tracker", .mint, "creditcard.fill")
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { screenWidth in
                    HeaderView(eyebrow: "Quick logs", title: "Track", systemImage: "plus")

                    ForEach(sections, id: \.0) { section in
                        TrackerCard(
                            title: section.0,
                            detail: section.1,
                            color: section.2,
                            icon: section.3,
                            isCompact: screenWidth < 390
                        )
                    }
                }
            }
        }
    }
}

private struct TrackerCard: View {
    var title: String
    var detail: String
    var color: Color
    var icon: String
    var isCompact: Bool

    var body: some View {
        Card(padding: isCompact ? 14 : 18) {
            HStack(spacing: isCompact ? 12 : 14) {
                AdaptiveIconTile(color: color, icon: icon, size: isCompact ? 50 : 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font((isCompact ? Font.headline : Font.title3).weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.dilMuted)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.dilMuted)
            }
        }
    }
}
