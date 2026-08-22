import SwiftUI

public enum BadeFontFamily: Sendable, Equatable {
    case system
    /// A bundled family, e.g. "NotoSansGeorgian".
    case custom(String)
}

/// The only place the typeface and its sizes are chosen. Point `family` at a bundled font and the
/// whole app restyles; no view names a font or a size.
public enum BadeTypography {
    public static let family: BadeFontFamily = .system

    public static let totalSize: CGFloat = 92
    /// The name on the launch screen: bigger than any heading, smaller than the one total that
    /// outranks it.
    public static let wordmarkSize: CGFloat = 64
    public static let displaySize: CGFloat = 40
    public static let titleSize: CGFloat = 22
    public static let headlineSize: CGFloat = 17
    public static let bodySize: CGFloat = 16
    public static let captionSize: CGFloat = 13
    public static let labelSize: CGFloat = 11
    public static let labelTracking: CGFloat = 1.2
    /// How much smaller the tetri are set than the lari beside them.
    public static let fractionScale: CGFloat = 0.6

    /// System styles scale with Dynamic Type on their own; a custom family scales via `relativeTo`.
    static func font(
        _ size: CGFloat, relativeTo style: Font.TextStyle, weight: Font.Weight = .regular
    ) -> Font {
        switch family {
        case .system: .system(style, weight: weight)
        case .custom(let name): .custom(name, size: size, relativeTo: style).weight(weight)
        }
    }
}

extension Font {
    /// The hero total is oversized, so its view supplies a @ScaledMetric size.
    public static func badeTotal(size: CGFloat) -> Font {
        switch BadeTypography.family {
        case .system: .system(size: size, weight: .semibold).monospacedDigit()
        case .custom(let name): .custom(name, fixedSize: size).weight(.semibold).monospacedDigit()
        }
    }

    /// Screen-opening question, the largest text after the hero total.
    public static var badeDisplay: Font {
        BadeTypography.font(BadeTypography.displaySize, relativeTo: .largeTitle, weight: .bold)
    }
    public static var badeTitle: Font {
        BadeTypography.font(BadeTypography.titleSize, relativeTo: .title2, weight: .semibold)
    }
    public static var badeHeadline: Font {
        BadeTypography.font(BadeTypography.headlineSize, relativeTo: .headline, weight: .semibold)
    }
    public static var badeBody: Font {
        BadeTypography.font(BadeTypography.bodySize, relativeTo: .body)
    }
    /// Money uses tabular figures so columns of amounts stay aligned as digits change.
    public static var badeAmount: Font {
        BadeTypography.font(BadeTypography.bodySize, relativeTo: .body, weight: .medium)
            .monospacedDigit()
    }
    public static var badeCaption: Font {
        BadeTypography.font(BadeTypography.captionSize, relativeTo: .caption)
    }
    /// A caption carrying the one word or figure that matters in its line.
    public static var badeCaptionStrong: Font {
        BadeTypography.font(BadeTypography.captionSize, relativeTo: .caption, weight: .semibold)
    }
    public static var badeLabel: Font {
        BadeTypography.font(BadeTypography.labelSize, relativeTo: .caption2, weight: .semibold)
    }
}

extension View {
    /// Uppercase section labels, with the tracking the design carries. `tint` promotes a label the
    /// design colours differently; the default is the quiet one.
    public func badeSectionLabel(tint: Color? = nil) -> some View {
        modifier(BadeSectionLabel(tint: tint))
    }
}

private struct BadeSectionLabel: ViewModifier {
    @Environment(\.badeTheme) private var theme

    let tint: Color?

    func body(content: Content) -> some View {
        content
            .font(.badeLabel)
            .textCase(.uppercase)
            .tracking(BadeTypography.labelTracking)
            .foregroundStyle(tint ?? theme.inkFaint)
            // Every section heading in the app goes through here, so this is the one place that
            // makes the rotor's Headings mode work — without it there was nothing to jump between
            // and a screen had to be swiped through row by row.
            .accessibilityAddTraits(.isHeader)
    }
}
