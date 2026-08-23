import Core
import DesignSystem
import Localization
import SwiftUI

struct SubscriptionListRow: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    let row: SubscriptionRow
    let currency: String

    /// Plain content, not a button. A button here fights the row's own swipe and long-press
    /// recognisers, and the lifted context-menu preview would carry the button rather than the
    /// row — background and all left behind. ⑥ Detail turns this into a `NavigationLink`, which
    /// is what a tappable list row is supposed to be.
    var body: some View {
        HStack(spacing: .sm) {
            MerchantMonogram(letter: row.monogram, merchant: row.subscription.merchant)

            VStack(alignment: .leading, spacing: .xxs) {
                Text(row.subscription.merchant)
                    .font(.badeBody)
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                detail
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: .xs)

            Text(row.displayAmount(in: currency), format: .badeMoney(row.displayCurrency(currency)))
                .font(.badeAmount)
                .foregroundStyle(theme.ink)
        }
        .frame(minHeight: BadeLayout.minimumTapTarget)
        .contentShape(.rect)
    }

    /// The billed price only earns its place when it differs from what is charged; otherwise the
    /// amount on the right already says it and the date is the useful half. What the service
    /// actually costs is the interesting half, so it carries the weight and the date recedes.
    @ViewBuilder
    private var detail: some View {
        if row.showsBilledPrice(against: currency) {
            Text(billedAndDate)
        } else {
            Text(row.nextCharge, format: .dateTime.month(.abbreviated).day())
        }
    }

    private var billedAndDate: AttributedString {
        var billed = AttributedString(billedText)
        billed.font = .badeCaptionStrong
        billed.foregroundColor = theme.ink
        let separator = String.badeLocalized(.subscriptions.separator, in: locale)
        return billed + AttributedString(separator + nextChargeText)
    }

    /// The price as billed, carrying its cadence when that is not monthly — "$379.75 a year". The
    /// figure on the right is a twelfth of this, so without saying so the row shows two amounts and
    /// explains neither.
    private var billedText: String {
        let money = row.billed.formatted(.badeMoney(row.subscription.currency).locale(locale))
        guard let phrase = row.subscription.cadence.billedPhrase(money) else { return money }
        return .badeLocalized(phrase, in: locale)
    }

    private var nextChargeText: String {
        row.nextCharge.formatted(.dateTime.month(.abbreviated).day().locale(locale))
    }
}

/// The brief asks for logos where they exist and a clean monogram where they do not. Nothing
/// bundles logos yet, so every row gets the monogram — but each in its merchant's own colour,
/// worked out from the name, so a column of them is scannable rather than thirty identical tiles.
struct MerchantMonogram: View {
    let letter: String
    let merchant: String

    var body: some View {
        Text(letter)
            .font(.badeHeadline)
            .foregroundStyle(colour)
            .frame(width: MonogramMetrics.size, height: MonogramMetrics.size)
            .background(
                RoundedRectangle(cornerRadius: MonogramMetrics.cornerRadius, style: .continuous)
                    .fill(colour.opacity(BadeMerchantMetrics.tintOpacity))
            )
            .accessibilityHidden(true)
    }

    private var colour: Color { .badeMerchant(folded: MerchantName.folded(merchant)) }
}
