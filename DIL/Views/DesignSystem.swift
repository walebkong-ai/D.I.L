import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    #if canImport(UIKit)
    static let dilBackground = Color(uiColor: .systemGroupedBackground)
    static let dilSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let dilLine = Color(uiColor: .separator)
    static let dilInk = Color(uiColor: .label)
    static let dilMuted = Color(uiColor: .secondaryLabel)
    #else
    static let dilBackground = Color.gray.opacity(0.08)
    static let dilSurface = Color.white
    static let dilLine = Color.gray.opacity(0.3)
    static let dilInk = Color.primary
    static let dilMuted = Color.secondary
    #endif
    static let dilAccent = Color.accentColor
    static let dilHero = Color(red: 0.045, green: 0.055, blue: 0.075)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }
}

struct Card<Content: View>: View {
    var background: Color = .dilSurface
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 8
    let content: Content

    init(background: Color = .dilSurface, padding: CGFloat = 18, cornerRadius: CGFloat = 8, @ViewBuilder content: () -> Content) {
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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.dilLine.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }
}

struct HeaderView: View {
    var eyebrow: String
    var title: String
    var systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.dilHero)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dilMuted)
                    .textCase(.uppercase)
                Text(title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.dilInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
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
            .background(Color.dilBackground.ignoresSafeArea())
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
        RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                Capsule().fill(Color.dilMuted.opacity(0.2))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(1, max(0, progress)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(min(1, max(0, progress)) * 100)) percent")
    }
}

struct SectionHeader: View {
    var title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(Color.dilInk)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dilMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.top, 4)
    }
}

struct StatusBadge: View {
    var text: String
    var color: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
            }
            Text(text)
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.14), in: Capsule())
    }
}

struct MetricBlock: View {
    var title: String
    var value: String
    var detail: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.dilInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct EmptyStatePanel: View {
    var icon: String
    var title: String
    var detail: String
    var color: Color = .dilBlue

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 14) {
                AdaptiveIconTile(color: color, icon: icon, size: 52)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.dilInk)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.dilMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
