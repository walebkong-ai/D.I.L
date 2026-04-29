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
                ScrollView {
                    VStack(spacing: 18) {
                        HeaderView(eyebrow: "Life areas", title: "Goals", systemImage: "target")

                        ForEach(goals, id: \.0) { goal in
                            Card {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(goal.0).font(.title3.weight(.bold))
                                        Spacer()
                                        Text("\(Int(goal.2 * 100))%")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(goal.3)
                                    }
                                    Text(goal.1)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.dilMuted)
                                    ProgressBar(progress: goal.2, color: goal.3)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}
