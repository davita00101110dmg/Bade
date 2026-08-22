import Core
import DesignSystem
import Localization
import SwiftUI

/// The number the whole product exists to show. It is the largest type in the app, and §14.7's
/// arrival moment lands on it.
struct MonthlyTotalHeader: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var totalSize = BadeTypography.totalSize

    let total: Decimal
    let annual: Decimal
    let currency: String
    let count: Int
    let unconvertibleCount: Int

    /// Owned by the screen, not this row: a list row is destroyed when it scrolls away and
    /// rebuilt when it comes back, which replayed the count-up and re-fired the haptic every time.
    @Binding var hasArrived: Bool

    /// Every tap on the figure itself. What the screen counts them for is its own business.
    let onTotalTapped: () -> Void

    /// The two ends of the count. Both are held in state rather than read from `total` directly:
    /// passing the live total moved the figure the instant the data changed, before the count had
    /// begun. Which of the two is on screen depends on `counted`, and the other is the one free to
    /// be replaced.
    @State private var countingFrom: Decimal = 0
    @State private var countingTo: Decimal = 0
    @State private var counted: Double = 0
    @State private var hasLanded = false
    /// A currency change re-denominates the same money; it must not be counted through, or picking
    /// dollars looks like the total moving.
    @State private var countedCurrency = ""

    var body: some View {
        VStack(spacing: .xxs) {
            Text(.subscriptions.perMonth)
                .badeSectionLabel()

            CountingTotal(
                counted: counted, from: countingFrom, to: countingTo, currency: currency,
                size: totalSize
            )
            .foregroundStyle(theme.accent)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentShape(.rect)
                .onTapGesture(perform: onTotalTapped)

            // "₾0 a year · 0 subscriptions" restates the zero twice; say what it means instead.
            Text(count == 0 ? .subscriptions.nothingCharging : .subscriptions.yearAndCount(annualText, count))
                .font(.badeBody)
                .foregroundStyle(theme.inkMuted)

            if unconvertibleCount > 0 {
                Text(.subscriptions.unconvertible(unconvertibleCount))
                    .font(.badeCaption)
                    .foregroundStyle(theme.warning)
                    .padding(.top, .xxs)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        // Ignored rather than combined, because the figure on screen is mid-count for the first
        // second and VoiceOver would read whatever it was passing through. Everything else in the
        // block is stable, so it is spelled out here — combining and then overriding the label
        // announced the total and silently dropped the year, the count and the warning with it.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.subscriptions.perMonth))
        .accessibilityValue(spoken)
        .badeFeedback(.itemAppeared, trigger: hasLanded)
        .task(id: total) { await count() }
    }

    /// The settled figures, never the one counting up to them. Joined the way a reminder joins its
    /// own spoken parts, so the separator is localised rather than a comma written into a view.
    private var spoken: Text {
        var parts = [
            total.formatted(.badeMoney(currency).locale(locale)),
            .badeLocalized(
                count == 0
                    ? .subscriptions.nothingCharging
                    : .subscriptions.yearAndCount(annualText, count), in: locale),
        ]
        if unconvertibleCount > 0 {
            parts.append(
                .badeLocalized(.subscriptions.unconvertible(unconvertibleCount), in: locale))
        }
        let separator = String.badeLocalized(.subscriptions.separator, in: locale)
        return Text(verbatim: parts.joined(separator: separator))
    }

    /// Counts from whatever was on screen to whatever is now true — up on an import or an add, down
    /// on a delete, and down to nothing when everything goes. Only the arrival fires the haptic; a
    /// total moving because the data moved is information, not an event.
    ///
    /// `counted` alternates between the two ends rather than resetting, and the endpoint replaced is
    /// always the one *not* on screen. Resetting cannot work: `counted = 0` and an animated
    /// `counted = 1` in the same block are coalesced into a single update, so the value never
    /// changes and there is nothing for `CountingTotal` to interpolate. That is why the figure used
    /// to jump to its new value and let the list's ambient animation crossfade it.
    private func count() async {
        let isRedenomination = !countedCurrency.isEmpty && countedCurrency != currency
        countedCurrency = currency

        if isRedenomination || reduceMotion {
            countingFrom = total
            countingTo = total
            guard !isRedenomination else { return }
        } else {
            if counted == 1 {
                countingFrom = total
                withBadeAnimation(.badeTotalReveal, reduceMotion: reduceMotion) { counted = 0 }
            } else {
                countingTo = total
                withBadeAnimation(.badeTotalReveal, reduceMotion: reduceMotion) { counted = 1 }
            }
            try? await Task.sleep(for: .seconds(BadeMotion.totalReveal))
        }

        hasLanded = !hasArrived
        hasArrived = true
    }

    private var annualText: String {
        annual.formatted(.badeMoneyWhole(currency).locale(locale))
    }
}

/// Counts from one figure to another. `counted` is a unitless 0–1 fraction rather than the money
/// itself, so the amount stays `Decimal` throughout and only the progress is a Double.
private struct CountingTotal: View, Animatable {
    var counted: Double
    let from: Decimal
    let to: Decimal
    let currency: String
    let size: CGFloat

    nonisolated var animatableData: Double {
        get { counted }
        set { counted = newValue }
    }

    var body: some View {
        BadeMoneyText(showing, currency: currency, size: size, shimmers: true)
            // Without this the count is not a count. `Text` crossfades its own content by default,
            // so each interpolated frame gets faded into the next over the whole animation and the
            // figure dissolves between two numbers rather than travelling between them. This view
            // supplies every intermediate value itself; SwiftUI's job is only to draw them.
            .contentTransition(.identity)
    }

    private var showing: Decimal { from + (to - from) * Decimal(counted) }
}
