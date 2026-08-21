import Foundation
import SwiftUI

/// A headline amount with the tetri set smaller than the lari, seated on the same baseline.
/// `.badeMoneyWhole` drops them; at this size they are still worth showing, just not worth shouting.
public struct BadeMoneyText: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let amount: Decimal
    private let currency: String
    private let size: CGFloat
    private let shimmers: Bool

    public init(_ amount: Decimal, currency: String, size: CGFloat, shimmers: Bool = false) {
        self.amount = amount
        self.currency = currency
        self.size = size
        self.shimmers = shimmers
    }

    public var body: some View {
        if shimmers && !reduceMotion {
            TimelineView(.animation) { context in
                let cycle = context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: BadeMoneySheen.period)
                Text(styled)
                    .overlay { glint(at: cycle) }
                    .mask(Text(styled))
            }
        } else {
            Text(styled)
        }
    }

    /// A band of light crossing the figure, and nothing at all the rest of the time — so the total
    /// is its own solid colour except for the second it is caught.
    ///
    /// The band is the accent's own colour added to itself, not white: white lifts every channel
    /// towards grey and bleached the hue out of the one figure the app is built around. Adding a
    /// colour to itself raises its luminance and leaves the hue where it was.
    @ViewBuilder
    private func glint(at cycle: TimeInterval) -> some View {
        if cycle < BadeMoneySheen.pass {
            let travelled = cycle / BadeMoneySheen.pass * (1 + 2 * BadeMoneySheen.width)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: theme.accent.opacity(BadeMoneySheen.brightness), location: 0.5),
                    .init(color: .clear, location: 1),
                ],
                startPoint: UnitPoint(x: travelled - BadeMoneySheen.width * 2, y: 0),
                endPoint: UnitPoint(x: travelled, y: 1)
            )
            .blendMode(.plusLighter)
        }
    }

    private var styled: AttributedString {
        let split = BadeMoneySplit(amount, currency: currency, locale: locale)
        return run(split.head, at: size) + run(split.fraction, at: size * BadeTypography.fractionScale)
            + run(split.tail, at: size)
    }

    private func run(_ text: String, at size: CGFloat) -> AttributedString {
        var run = AttributedString(text)
        run.font = .badeTotal(size: size)
        return run
    }
}

/// The sheen's own numbers. Slow and shallow: this runs under a figure people are reading, and the
/// point is that it looks like light rather than like something happening.
public enum BadeMoneySheen {
    /// Seconds between one glint and the next. Most of it is still the figure simply sitting
    /// there — this is the gap, not the crossing, so shortening it changes how often the light
    /// comes round without hurrying it on its way across.
    public static let period: TimeInterval = 3.8
    /// How long the band takes to cross. Short against the period on purpose: the total is solid
    /// far more of the time than it is lit.
    public static let pass: TimeInterval = 0.9
    /// How much the band lifts what it crosses. Lower than it would be for white, because adding
    /// the accent to itself climbs fast.
    public static let brightness = 0.55
    /// The band's width as a share of the figure's, which is what makes it a glint and not a wash.
    public static let width: Double = 0.35
}
