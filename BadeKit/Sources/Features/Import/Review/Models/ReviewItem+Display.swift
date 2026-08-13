import Core
import Foundation
import Localization

extension ReviewItem {
    /// What actually left the account, falling back to the charge's own currency when the
    /// statement carried no rate for it.
    func displayAmount(in currency: String) -> Decimal { converted ?? subscription.amount }

    func displayCurrency(_ currency: String) -> String {
        converted == nil ? subscription.currency : currency
    }

    /// The sticker price, shown only when the bank converted the charge.
    func originalAmount(displayedIn currency: String) -> Decimal? {
        guard converted != nil, subscription.currency != currency else { return nil }
        return subscription.amount
    }

    func caption(in locale: Locale) -> LocalizedStringResource {
        .review.caption(subscription.occurrences.count, detail(in: locale))
    }

    /// That it stopped outranks everything else: a row saying "monthly" for something last charged
    /// in February reads as a live cost, which is the one thing it is not.
    private func detail(in locale: Locale) -> String {
        if subscription.hasEnded {
            let last = subscription.occurrences.map(\.date).max() ?? subscription.nextChargeDate
            return .badeLocalized(
                .review.ended(last.formatted(.dateTime.month(.wide).locale(locale))), in: locale)
        }
        if !subscription.priceChanges.isEmpty {
            return .badeLocalized(.review.priceChanged, in: locale)
        }
        if subscription.confidence == .probable {
            return subscription.occurrences.map(\.date).sorted()
                .map { $0.formatted(.dateTime.month(.abbreviated).locale(locale)) }
                .formatted(.list(type: .and, width: .narrow).locale(locale))
        }
        return .badeLocalized(subscription.cadence.localizedName, in: locale)
    }
}
