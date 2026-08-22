import Localization
import SwiftUI
import TipKit

/// ④ Subscriptions. Nothing in the interface can show a swipe, and pausing a subscription is
/// otherwise only findable by accident.
public struct SwipeARowTip: Tip {
    public init() {}

    public var title: Text { Text(.tip.swipeARowTitle) }
    public var message: Text? { Text(.tip.swipeARowMessage) }
    public var image: Image? { Image(systemName: "hand.draw") }
}

/// ⑤ Upcoming. A tile in a grid looks like a readout; only permission to tap it is missing.
public struct TapADayTip: Tip {
    public init() {}

    public var title: Text { Text(.tip.tapADayTitle) }
    public var message: Text? { Text(.tip.tapADayMessage) }
    public var image: Image? { Image(systemName: "hand.tap") }
}

extension View {
    /// Every tip in Bade wears this.
    ///
    /// The palette and the language are read here, in the presenting view, and handed to the style
    /// as values. A tip is presented by the system in a popover of its own, and presented content
    /// inherits none of what the app set above it — the same boundary that once ran the whole
    /// import flow in English, and that made the widget resolve a light palette on a dark tile.
    /// Nothing here depends on the environment reaching across it.
    public func badeTipStyle() -> some View {
        modifier(BadeTipStyling())
    }
}

private struct BadeTipStyling: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content.tipViewStyle(
            BadeTipStyle(theme: .matching(scheme, contrast: contrast), locale: locale))
    }
}

public struct BadeTipStyle: TipViewStyle {
    private let theme: BadeTheme
    private let locale: Locale

    init(theme: BadeTheme, locale: Locale) {
        self.theme = theme
        self.locale = locale
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: .sm) {
            configuration.image?
                .font(.badeHeadline)
                .foregroundStyle(theme.accent)
                // Decorative: the title says the same thing in words.
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: .xxs) {
                configuration.title
                    .font(.badeHeadline)
                    .foregroundStyle(theme.ink)
                configuration.message
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
            }

            Spacer(minLength: .zero)

            // A tip with no way out is a nag. Closing it is as final as performing the gesture.
            Button { configuration.tip.invalidate(reason: .tipClosed) } label: {
                Image(systemName: "xmark")
                    .font(.badeLabel)
                    .foregroundStyle(theme.inkFaint)
                    .frame(
                        width: BadeLayout.minimumTapTarget, height: BadeLayout.minimumTapTarget)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.common.dismiss))
        }
        .padding(.md)
        .background(theme.surfaceRaised)
        .environment(\.locale, locale)
    }
}
