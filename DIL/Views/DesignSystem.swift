import SwiftUI

extension Color {
    static let dilBackground = Color(red: 0.965, green: 0.968, blue: 0.975)
    static let dilInk = Color(red: 0.045, green: 0.055, blue: 0.075)
    static let dilMuted = Color(red: 0.44, green: 0.46, blue: 0.52)
    static let dilOrange = Color(red: 1.0, green: 0.46, blue: 0.16)
    static let dilBlue = Color(red: 0.33, green: 0.68, blue: 0.93)
    static let dilGreen = Color(red: 0.58, green: 0.82, blue: 0.35)
    static let dilPurple = Color(red: 0.55, green: 0.42, blue: 0.98)
    static let dilGold = Color(red: 0.98, green: 0.70, blue: 0.25)
}

struct ScreenBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.dilBackground.ignoresSafeArea()
            content
        }
    }
}

struct Card<Content: View>: View {
    var background: Color = .white
    let content: Content

    init(background: Color = .white, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }
}

struct HeaderView: View {
    var eyebrow: String
    var title: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.dilInk)
                .frame(width: 46, height: 46)
                .overlay(Image(systemName: systemImage).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.subheadline)
                    .foregroundStyle(Color.dilMuted)
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.dilInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer()
        }
    }
}

struct ProgressBar: View {
    var progress: Double
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.38))
                Capsule()
                    .fill(color)
                    .frame(width: max(8, geometry.size.width * progress))
            }
        }
        .frame(height: 8)
    }
}
