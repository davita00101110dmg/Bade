import DesignSystem
import Localization
import SwiftUI
import WidgetKit

/// A real month, split: what it costs, how much of it has already gone, and what is left. The app's
/// list levels every cadence into "a month"; only a calendar month can be halfway through.
public struct BadeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    private let snapshot: WidgetSnapshot

    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        if !snapshot.isPro {
            locked
        } else if !snapshot.hasData {
            empty
        } else if family == .systemMedium {
            medium
        } else {
            month
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: .md) {
            month
            divider
            coming
        }
    }

    /// What is still to leave the account this month, not what the month costs. The month's whole
    /// cost is underneath, because a figure that shrinks to nothing needs something to be a share of.
    private var month: some View {
        VStack(alignment: .leading, spacing: .xs) {
            Text(.widget.stillComing).badeSectionLabel()

            Spacer(minLength: .zero)

            BadeMoneyText(
                snapshot.remaining, currency: snapshot.currency, size: BadeTypography.displaySize
            )
            .foregroundStyle(theme.ink)
            .minimumScaleFactor(WidgetMetrics.totalScale)
            .lineLimit(1)

            BadeProgressBar(progress: snapshot.spentFraction)

            Text(remainder)
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A hairline rather than a gap: two columns of numbers need to be told apart.
    private var divider: some View {
        Rectangle()
            .fill(theme.border)
            .frame(width: WidgetMetrics.dividerWidth)
    }

    /// This month only, like the bar beside it. Late in a month there may be one charge left or
    /// none, and saying so is the point — borrowing next month's to fill the rows is what made the
    /// column disagree with its own heading.
    /// No heading of its own: the divider and the figure to its left already say what these are,
    /// and repeating "still coming" over them wasted the one line the rows could have used.
    private var coming: some View {
        VStack(alignment: .leading, spacing: .xs) {
            if snapshot.upcoming.isEmpty {
                Text(.widget.nothingLeft)
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
            } else {
                ForEach(snapshot.upcoming) { charge in
                    ChargeRow(charge: charge)
                }
            }

            Spacer(minLength: .zero)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// What the month costs in total, or — when nothing is left to pay — that it is all done, which
    /// is good news and should read as such rather than as a zero with no comment.
    private var remainder: LocalizedStringResource {
        guard snapshot.remaining > 0 else { return .widget.allCharged }
        return .widget.ofMonth(
            snapshot.monthTotal.formatted(.badeMoney(snapshot.currency).locale(locale)))
    }

    private var locked: some View {
        VStack(alignment: .leading, spacing: .xxs) {
            Text(.pro.badge).badeSectionLabel(tint: theme.accent)
            Text(.widget.locked)
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var empty: some View {
        Text(.widget.empty)
            .font(.badeCaption)
            .foregroundStyle(theme.inkMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct ChargeRow: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    let charge: WidgetSnapshot.Charge

    var body: some View {
        HStack(spacing: .xs) {
            Text(verbatim: charge.merchant)
                .font(.badeCaption)
                .foregroundStyle(theme.ink)
                .lineLimit(1)

            Spacer(minLength: .zero)

            Text(verbatim: day)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)

            Text(charge.amount, format: .badeMoney(charge.currency))
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    /// A weekday inside the coming week, a date beyond it — the shortest thing that is unambiguous.
    private var day: String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: charge.date).day ?? 0
        let format: Date.FormatStyle =
            days < 7 ? .dateTime.weekday(.abbreviated) : .dateTime.day().month(.abbreviated)
        return charge.date.formatted(format.locale(locale))
    }
}

/// The widget's own dimensions, which are its business and not the spacing scale's.
public enum WidgetMetrics {
    /// How far the total may shrink before it wraps — a five-figure sum still has to fit.
    public static let totalScale = 0.5
    public static let dividerWidth: CGFloat = 1
}
