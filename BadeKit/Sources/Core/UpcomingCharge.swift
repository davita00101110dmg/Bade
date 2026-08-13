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
    /// Everything falling in a half-open window: what a statement recorded, and what the rhythm says
    /// happened or is coming since.
    ///
    /// A statement ends before today does. A charge due in the days between belongs to neither half
    /// — not recorded, not yet future — so the month on screen would have a hole in it. Projections
    /// therefore reach back to the start of *this* month, and no further: an older month shows only
    /// what was recorded, because a month Bade never saw should stay empty rather than be filled
    /// with charges nobody can vouch for. Recorded charges include subscriptions since cancelled,
    /// because those charges still happened; projections do not, because those never will.
    public func upcomingCharges(
        from start: Date, before end: Date, today: Date, calendar: Calendar = .current
    ) -> [UpcomingCharge] {
        // The split is the start of today, not the instant: a charge due today is still coming,
        // and putting the boundary mid-day would drop it from both halves.
        let boundary = calendar.startOfDay(for: today)
        let thisMonth =
            calendar.date(from: calendar.dateComponents([.year, .month], from: boundary)) ?? boundary

        var charges: [UpcomingCharge] = []
        for subscription in self {
            let recorded = recorded(subscription, from: start, before: end, until: boundary)
            charges += recorded
            guard subscription.isActive else { continue }

            // A day a statement vouched for is never also guessed at.
            let seen = Set(recorded.map { calendar.startOfDay(for: $0.date) })
            charges +=
                projected(
                    subscription, from: Swift.max(start, thisMonth), before: end,
                    calendar: calendar
                )
                .filter { !seen.contains(calendar.startOfDay(for: $0.date)) }
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
