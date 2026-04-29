import SwiftUI

struct GoalsView: View {
    private let goals: [(String, String, Double, Color)] = [
        ("Finals Focus", "12 of 20 study blocks", 0.60, .dilBlue),
        ("Balanced Body", "3 of 4 workouts", 0.75, .dilOrange),
        ("Better Sleep", "5 of 7 consistent nights", 0.71, .dilPurple),
        ("Budget Guard", "$82 under weekly limit", 0.82, .dilGreen)
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    HeaderView(eyebrow: "Life areas", title: "Goals", systemImage: "target")

                    ForEach(goals, id: \.0) { goal in
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(goal.0)
                                        .font(.title3.weight(.bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.78)
                                    Spacer(minLength: 12)
                                    Text("\(Int(goal.2 * 100))%")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(goal.3)
                                        .lineLimit(1)
                                }
                                Text(goal.1)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.dilMuted)
                                    .lineLimit(2)
                                ProgressBar(progress: goal.2, color: goal.3)
                            }
                        }
                    }
                }
            }
        }
    }
}
