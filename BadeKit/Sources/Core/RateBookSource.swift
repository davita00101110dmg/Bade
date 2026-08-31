import Foundation

/// The one rate book every total is read against: what statements observed, plus — for the pairs
/// they never converted — what the publisher had for the days around it.
///
/// Observed rates alone are not enough, and on some accounts they are nothing at all. A charge paid
/// from a balance already in its own currency never touched a rate, so an account holding lari,
/// dollars and euros and paying each from its own balance records not one conversion. Every one of
/// those subscriptions was then unconvertible, which meant the headline figure quietly left them
/// out and Settings hid the row that could have changed what it was shown in.
public struct RateBookSource: Sendable {
    private let rates: any RateRepository
    private let subscriptions: any SubscriptionRepository
    private let published: any OfficialRateSource
    private let base: String
    private let calendar: Calendar

    public init(
        rates: any RateRepository,
        subscriptions: any SubscriptionRepository,
        published: any OfficialRateSource,
        base: String,
        calendar: Calendar = .current
    ) {
        self.rates = rates
        self.subscriptions = subscriptions
        self.published = published
        self.base = base
        self.calendar = calendar
    }

    /// How far back to look for a publication. A central bank publishes on working days, so a total
    /// read on a Sunday needs Friday's — and a Monday holiday puts that three days behind.
    private static let daysBack = 3

    public func book(totalling currency: String, on date: Date = .now) async -> RateBook {
        var book = (try? await rates.observedRates()) ?? RateBook()
        let stored = (try? await subscriptions.all()) ?? []
        // The base is never asked for: a publisher does not list its own currency, and asking for
        // one it can never answer marks every day incomplete and re-fetches it on every launch.
        let wanted = Set(stored.map(\.currency)).union([currency]).subtracting([base])
        guard !wanted.isEmpty else { return book }

        book.record(await published.rates(for: wanted, on: days(ending: date)), base: base)
        return book
    }

    private func days(ending date: Date) -> Set<Date> {
        let today = calendar.startOfDay(for: date)
        return Set(
            (0...Self.daysBack).compactMap {
                calendar.date(byAdding: .day, value: -$0, to: today)
            })
    }
}
