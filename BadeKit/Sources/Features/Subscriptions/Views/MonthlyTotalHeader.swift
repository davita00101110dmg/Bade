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

    @State private var revealed: Double = 0
    @State private var hasLanded = false

    var body: some View {
        VStack(spacing: .xxs) {
            Text(.subscriptions.perMonth)
                .badeSectionLabel()

            CountingTotal(revealed: revealed, total: total, currency: currency)
                .font(.badeTotal(size: totalSize))
                .foregroundStyle(theme.accent)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

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
        .accessibilityLabel(Text(total, format: .badeMoneyWhole(currency)))
        .badeFeedback(.itemAppeared, trigger: hasLanded)
        .task(id: total) { await reveal() }
    }

    private func reveal() async {
        guard total > 0 else { return revealed = 1 }
        hasLanded = false
        revealed = 0
        guard !reduceMotion else {
            revealed = 1
            hasLanded = true
            return
        }
        withBadeAnimation(.badeTotalReveal, reduceMotion: reduceMotion) { revealed = 1 }
        try? await Task.sleep(for: .seconds(BadeMotion.totalReveal))
        hasLanded = true
    }

    private var annualText: String {
        annual.formatted(.badeMoneyWhole(currency).locale(locale))
    }
}

/// Counts from nothing up to the total. `revealed` is a unitless 0–1 fraction rather than the
/// money itself, so the amount stays `Decimal` throughout and only the progress is a Double.
private struct CountingTotal: View, Animatable {
    var revealed: Double
    let total: Decimal
    let currency: String

    nonisolated var animatableData: Double {
        get { revealed }
        set { revealed = newValue }
    }

    var body: some View {
        Text(total * Decimal(revealed), format: .badeMoneyWhole(currency))
    }
}
