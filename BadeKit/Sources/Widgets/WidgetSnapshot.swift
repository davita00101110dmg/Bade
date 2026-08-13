import Core
import Foundation

/// Everything the home screen shows, worked out by the app and handed over ready to draw. The
/// widget runs in its own process: giving it figures rather than the store keeps SwiftData, the rate
/// book and StoreKit out of it entirely.
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public struct Charge: Codable, Equatable, Sendable, Identifiable {
        public let merchant: String
        public let amount: Decimal
        public let currency: String
        public let date: Date

        public var id: String { "\(merchant)|\(date.timeIntervalSince1970)" }

        public init(merchant: String, amount: Decimal, currency: String, date: Date) {
            self.merchant = merchant
            self.amount = amount
            self.currency = currency
            self.date = date
        }
    }

    /// This calendar month's charges — what was recorded before today plus what is due after it.
    /// The same figure the calendar screen totals, not the levelled "a month" the list shows: only a
    /// real month can be split into what has gone and what has not.
    public let monthTotal: Decimal
    /// Of that, what is still to come. `monthTotal - remaining` is what has already left.
    public let remaining: Decimal
    public let currency: String
    /// The soonest few, one row per subscription. Only what a medium widget has room for.
    public let upcoming: [Charge]
    /// Widgets are part of Pro. Written either way, so the widget can say why it is empty.
    public let isPro: Bool
    /// The language the app is set to, which is not the phone's: Bade overrides its own locale, and
    /// a separate process has no way of knowing that. `nil` follows the device.
    public let localeIdentifier: String?

    public init(
        monthTotal: Decimal, remaining: Decimal, currency: String, upcoming: [Charge], isPro: Bool,
        localeIdentifier: String? = nil
    ) {
        self.monthTotal = monthTotal
        self.remaining = remaining
        self.currency = currency
        self.upcoming = upcoming
        self.isPro = isPro
        self.localeIdentifier = localeIdentifier
    }

    /// What the widget renders in — words, weekdays and where the currency symbol goes.
    public var locale: Locale {
        localeIdentifier.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
    }

    /// How many charges a medium widget has room for without setting the rows too tight.
    public static let upcomingLimit = 3

    /// What a widget shows before the app has ever run, or with nothing stored.
    public static let empty = WidgetSnapshot(
        monthTotal: 0, remaining: 0, currency: "", upcoming: [], isPro: false)

    public var hasData: Bool { monthTotal > 0 || !upcoming.isEmpty }

    /// How much of the month has already been charged, for the bar. Nothing due at all reads as
    /// done rather than as an empty bar.
    public var spentFraction: Double {
        guard monthTotal > 0 else { return 1 }
        return Double(truncating: ((monthTotal - remaining) / monthTotal) as NSDecimalNumber)
    }
}

extension WidgetSnapshot {
    /// Built from what is stored, in the currency the app is totalling in.
    public init(
        subscriptions: [Subscription],
        currency: String,
        rates: RateBook,
        isPro: Bool,
        localeIdentifier: String? = nil,
        from now: Date = .now,
        calendar: Calendar = .current
    ) {
        let today = calendar.startOfDay(for: now)
        let monthStart =
            calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? today
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

        let month = subscriptions.upcomingCharges(
            from: monthStart, before: monthEnd, today: now, calendar: calendar)

        // Two months out so three rows can be filled even when subscriptions are sparse — but one
        // row per subscription, or a monthly charge would take two of the three saying the same name.
        let horizon = calendar.date(byAdding: .month, value: 2, to: now) ?? now
        var seen: Set<UUID> = []
        let next = subscriptions.upcomingCharges(
            from: today, before: horizon, today: now, calendar: calendar
        )
        .filter { seen.insert($0.subscription.id).inserted }

        func converted(_ charge: UpcomingCharge) -> Decimal? {
            rates.convert(charge.amount, from: charge.currency, to: currency, on: charge.date)
        }

        self.init(
            monthTotal: month.reduce(Decimal.zero) { $0 + (converted($1) ?? 0) },
            remaining: month.filter { $0.date >= today }
                .reduce(Decimal.zero) { $0 + (converted($1) ?? 0) },
            currency: currency,
            upcoming: next.prefix(WidgetSnapshot.upcomingLimit).map { charge in
                // Unconvertible stays in its own currency rather than being dropped, exactly as
                // the calendar and the list show it.
                let amount = converted(charge)
                return Charge(
                    merchant: charge.subscription.merchant,
                    amount: amount ?? charge.amount,
                    currency: amount == nil ? charge.currency : currency,
                    date: charge.date)
            },
            isPro: isPro,
            localeIdentifier: localeIdentifier)
    }
}
