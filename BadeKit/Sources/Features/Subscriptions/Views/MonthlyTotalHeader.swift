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

    @State private var countingFrom: Decimal = 0
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
                counted: counted, from: countingFrom, to: total, currency: currency, size: totalSize
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(total, format: .badeMoney(currency)))
        .badeFeedback(.itemAppeared, trigger: hasLanded)
        .task(id: total) { await count() }
    }

    /// Counts from whatever was on screen to whatever is now true — up when an import lands, down
    /// to nothing when everything is deleted. Only the arrival fires the haptic; a total moving
    /// because the data moved is information, not an event.
    private func count() async {
        let isRedenomination = !countedCurrency.isEmpty && countedCurrency != currency
        countedCurrency = currency

        if !isRedenomination && !reduceMotion {
            counted = 0
            withBadeAnimation(.badeTotalReveal, reduceMotion: reduceMotion) { counted = 1 }
            try? await Task.sleep(for: .seconds(BadeMotion.totalReveal))
        }
        countingFrom = total
        counted = 1

        guard !isRedenomination else { return }
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
    }

    private var showing: Decimal { from + (to - from) * Decimal(counted) }
}
