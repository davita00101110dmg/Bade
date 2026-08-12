import Foundation

/// A charge on a day: either one that was recorded from a statement, or one the rhythm says is
/// coming. Never stored — recomputed from the subscription every time it is shown.
public struct UpcomingCharge: Equatable, Sendable, Identifiable {
    public let subscription: Subscription
    public let date: Date
    /// What was billed, which for a recorded charge is not always the current price.
    public let amount: Decimal
    public let currency: String

    public init(subscription: Subscription, date: Date, amount: Decimal, currency: String) {
        self.subscription = subscription
        self.date = date
        self.amount = amount
        self.currency = currency
    }

    public var id: String { "\(subscription.id)|\(date.timeIntervalSince1970)" }

    /// Weekly billing across a decade of stale dates, so the roll-forward always terminates.
    static let projectionLimit = 600
}

extension Collection<Subscription> {
    /// Everything falling in a half-open window: what was actually charged up to today, and what
    /// the rhythm says is coming after it.
    ///
    /// The two never overlap and neither is guessed. A past month shows only what a statement
    /// recorded — nothing is projected backwards, so a month Bade never saw stays empty rather
    /// than being filled with charges nobody can vouch for. Recorded charges include subscriptions
    /// since cancelled, because those charges still happened.
    public func upcomingCharges(
        from start: Date, before end: Date, today: Date, calendar: Calendar = .current
    ) -> [UpcomingCharge] {
        // The split is the start of today, not the instant: a charge due today is still coming,
        // and putting the boundary mid-day would drop it from both halves.
        let boundary = calendar.startOfDay(for: today)
        var charges: [UpcomingCharge] = []
        for subscription in self {
            charges += recorded(subscription, from: start, before: end, until: boundary)
            guard subscription.isActive else { continue }
            charges += projected(
                subscription, from: Swift.max(start, boundary), before: end, calendar: calendar)
        }
        return charges.sorted {
            ($0.date, $0.subscription.merchant) < ($1.date, $1.subscription.merchant)
        }
    }

    private func recorded(
        _ subscription: Subscription, from start: Date, before end: Date, until boundary: Date
    ) -> [UpcomingCharge] {
        subscription.charges
            .filter { $0.date >= start && $0.date < end && $0.date < boundary }
            .map {
                UpcomingCharge(
                    subscription: subscription, date: $0.date, amount: $0.amount,
                    currency: $0.currency)
            }
    }

    /// A next charge date already in the past means the statement is old rather than the
    /// subscription stopped — lapse is judged against the end of the statement, never against
    /// today — so the rhythm is rolled forward into the window instead of being dropped.
    private func projected(
        _ subscription: Subscription, from start: Date, before end: Date, calendar: Calendar
    ) -> [UpcomingCharge] {
        var charges: [UpcomingCharge] = []
        let anchor = subscription.nextChargeDate
        var period = 0
        var date = anchor
        while date < end, period < UpcomingCharge.projectionLimit {
            if date >= start {
                charges.append(
                    UpcomingCharge(
                        subscription: subscription, date: date, amount: subscription.amount,
                        currency: subscription.currency))
            }
            period += 1
            date = subscription.cadence.charge(after: anchor, periods: period, in: calendar)
        }
        return charges
    }
}
