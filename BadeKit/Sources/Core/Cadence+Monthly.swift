import Foundation

extension Cadence {
    /// Multiply before dividing: `amount * (1/3)` loses exactness in Decimal, `amount / 3` does not.
    public func monthlyEquivalent(of amount: Decimal) -> Decimal {
        switch self {
        case .weekly: amount * 52 / 12
        case .monthly: amount
        case .quarterly: amount / 3
        case .semiannual: amount / 6
        case .annual: amount / 12
        }
    }
}

extension Subscription {
    /// What this subscription costs per month, in its own currency.
    public var monthlyAmount: Decimal { cadence.monthlyEquivalent(of: amount) }
}

extension Collection<Subscription> {
    /// The headline figure: every active subscription normalised to a monthly cost in one currency.
    /// Anything that cannot be converted is reported separately rather than silently dropped.
    public func monthlyTotal(in currency: String, rates: RateBook) -> (
        total: Decimal, unconvertible: [Subscription]
    ) {
        var total = Decimal(0)
        var unconvertible: [Subscription] = []
        for subscription in self where subscription.isActive {
            if let converted = rates.convert(
                subscription.monthlyAmount, from: subscription.currency, to: currency)
            {
                total += converted
            } else {
                unconvertible.append(subscription)
            }
        }
        return (total, unconvertible)
    }
}
