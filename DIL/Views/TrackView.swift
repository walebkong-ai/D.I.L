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
                ScrollView {
                    VStack(spacing: 18) {
                        HeaderView(eyebrow: "Quick logs", title: "Track", systemImage: "plus")

                        ForEach(sections, id: \.0) { section in
                            TrackerCard(title: section.0, detail: section.1, color: section.2, icon: section.3)
                        }
                    }
                    .padding(20)
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

    var body: some View {
        Card {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.22))
                    .frame(width: 58, height: 58)
                    .overlay(Image(systemName: icon).font(.title3.weight(.bold)).foregroundStyle(color))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.title3.weight(.bold))
                    Text(detail).font(.subheadline).foregroundStyle(Color.dilMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.dilMuted)
            }
        }
    }
}
