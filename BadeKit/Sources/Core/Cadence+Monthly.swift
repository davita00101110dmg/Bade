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

/// Anything that carries a price in a currency. Two things do — what is stored, and what an import
/// has just detected — and both have to be able to answer what currency a screen should total in.
public protocol Priced {
    var currency: String { get }
}

extension Subscription: Priced {}
extension DetectedSubscription: Priced {}

extension Collection where Element: Priced {
    /// The currency most of them are billed in, which is the one worth totalling in: it leaves the
    /// fewest charges needing a rate that may not exist. Ties break alphabetically so the answer
    /// does not depend on what order they arrived in.
    public var predominantCurrency: String? {
        let counts = reduce(into: [String: Int]()) { $0[$1.currency, default: 0] += 1 }
        return counts.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }
}

extension Collection<Subscription> {
    /// The headline figure: every active subscription normalised to a monthly cost in one currency.
    /// Anything that cannot be converted is reported separately rather than silently dropped.
    ///
    /// `on` is the date the rates are read at, and it is one date for the whole sum rather than each
    /// subscription's own history. Rates are picked by nearest observation, so converting each line
    /// at a different date made this total and the calendar's disagree by a few tetri for no reason
    /// a reader could ever see. Money still to be paid is worth what today's rate says it is.
    public func monthlyTotal(in currency: String, rates: RateBook, on date: Date) -> (
        total: Decimal, unconvertible: [Subscription]
    ) {
        var total = Decimal(0)
        var unconvertible: [Subscription] = []
        for subscription in self where subscription.isActive {
            if let converted = rates.convert(
                subscription.monthlyAmount, from: subscription.currency, to: currency, on: date)
            {
                total += converted
            } else {
                unconvertible.append(subscription)
            }
        }
        return (total, unconvertible)
    }

    /// The currencies a total can honestly be shown in: those every active subscription converts
    /// into, leaving nothing unconvertible.
    ///
    /// Offering more than this is what produced a screen of three hundred currencies where picking
    /// almost any of them totalled to zero. `RateBook` never extrapolates and never triangulates —
    /// a pair is either observed or it is not — so holding GEL-USD says nothing whatever about
    /// GEL-JPY, and the picker was promising conversions that could not happen.
    ///
    /// Nor is "the currencies you are charged in" the same question. A multi-currency account pays
    /// a dollar charge from a dollar balance and records no conversion doing it, so USD can be a
    /// currency you plainly hold and still be one your lari subscriptions cannot be shown in.
    ///
    /// Cancelled subscriptions do not restrict the choice, because they are not in the total.
    public func convertibleCurrencies(rates: RateBook, on date: Date) -> [String] {
        // The only codes that can ever succeed: a subscription's own, or one an observation names.
        let candidates = Set(map(\.currency))
            .union(rates.observations.flatMap { [$0.from, $0.to] })

        return
            candidates
            .filter { monthlyTotal(in: $0, rates: rates, on: date).unconvertible.isEmpty }
            .sorted()
    }
}
