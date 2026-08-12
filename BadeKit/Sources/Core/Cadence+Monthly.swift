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

extension Cadence {
    /// One billing period in calendar terms rather than days, so a monthly subscription lands on
    /// the same day of the month whatever that month's length.
    private var period: (component: Calendar.Component, value: Int) {
        switch self {
        case .weekly: (.day, 7)
        case .monthly: (.month, 1)
        case .quarterly: (.month, 3)
        case .semiannual: (.month, 6)
        case .annual: (.year, 1)
        }
    }

    /// Always measured from the same anchor, never stepped one period at a time: adding a month
    /// to the 31st gives the 28th, and stepping again from there would lose the 31st for good.
    public func charge(after date: Date, periods: Int = 1, in calendar: Calendar = .current)
        -> Date
    {
        calendar.date(byAdding: period.component, value: period.value * periods, to: date) ?? date
    }

    public func charge(before date: Date, in calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: period.component, value: -period.value, to: date) ?? date
    }
}

extension Subscription {
    /// What this subscription costs per month, in its own currency.
    public var monthlyAmount: Decimal { cadence.monthlyEquivalent(of: amount) }
}

extension Collection<Subscription> {
    /// The currency most subscriptions are billed in, which is the one worth totalling in: it
    /// leaves the fewest charges needing a rate that may not exist. Ties break alphabetically so
    /// the answer does not depend on what order the store handed them over.
    public var predominantCurrency: String? {
        let counts = reduce(into: [String: Int]()) { $0[$1.currency, default: 0] += 1 }
        return counts.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }

    /// The headline figure: every active subscription normalised to a monthly cost in one currency.
    /// Anything that cannot be converted is reported separately rather than silently dropped.
    public func monthlyTotal(in currency: String, rates: RateBook) -> (
        total: Decimal, unconvertible: [Subscription]
    ) {
        var total = Decimal(0)
        var unconvertible: [Subscription] = []
        for subscription in self where subscription.isActive {
            if let converted = rates.convert(
                subscription.monthlyAmount, from: subscription.currency, to: currency,
                on: subscription.lastChargeDate)
            {
                total += converted
            } else {
                unconvertible.append(subscription)
            }
        }
        return (total, unconvertible)
    }
}
