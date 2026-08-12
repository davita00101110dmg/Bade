import Core
import Foundation

/// What the form holds while it is being filled in. The amount stays text until it is saved: a
/// half-typed number is not a `Decimal`, and forcing one on every keystroke fights the typist.
public struct SubscriptionDraft: Equatable, Sendable {
    public var merchant: String
    public var amount: String
    public var currency: String
    public var cadence: Cadence
    public var nextChargeDate: Date
    public var isActive: Bool

    /// A blank form. The next charge is one period out until the date is chosen by hand.
    init(currency: String, today: Date, calendar: Calendar) {
        merchant = ""
        amount = ""
        self.currency = currency
        cadence = .monthly
        nextChargeDate = cadence.charge(after: today, in: calendar)
        isActive = true
    }

    init(_ subscription: Subscription) {
        merchant = subscription.merchant
        // `description` rather than a locale format: this is an editing buffer, not a reading of
        // money. `DecimalInput` accepts either separator when it comes back.
        amount = subscription.amount.description
        currency = subscription.currency
        cadence = subscription.cadence
        nextChargeDate = subscription.nextChargeDate
        isActive = subscription.isActive
    }
}
