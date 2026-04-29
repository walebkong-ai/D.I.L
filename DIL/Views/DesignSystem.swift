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
            Color.white.ignoresSafeArea()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}

struct Card<Content: View>: View {
    var background: Color = .white
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 22
    let content: Content

    init(background: Color = .white, padding: CGFloat = 18, cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.background = background
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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

struct AdaptiveScreen<Content: View>: View {
    let content: (CGFloat) -> Content

    init(@ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let horizontalPadding = width < 390 ? 16.0 : 20.0
            let contentWidth = min(width - horizontalPadding * 2, 480)

            ScrollView {
                VStack(spacing: width < 390 ? 14 : 18) {
                    content(width)
                }
                .frame(width: contentWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, width < 390 ? 14 : 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum Fluid {
    static func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

struct AdaptiveIconTile: View {
    var color: Color
    var icon: String
    var size: CGFloat = 54

    var body: some View {
        RoundedRectangle(cornerRadius: min(18, size * 0.32), style: .continuous)
            .fill(color.opacity(0.22))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: max(16, size * 0.36), weight: .bold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
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
