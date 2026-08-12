import Foundation

/// A central bank's published rate for one currency on one day: how many units of the display
/// currency one unit of the foreign currency was officially worth.
///
/// Distinct from `ObservedRate`, which is what a bank actually charged. The gap between the two
/// is the markup §8 exists to report, so the app must never confuse one for the other.
public struct OfficialRate: Equatable, Sendable, Codable {
    public let date: Date
    /// ISO 4217, the currency being priced.
    public let currency: String
    /// Units of the display currency per one unit of `currency`, already divided down from
    /// whatever quantity the publisher quotes in — some currencies are published per 100.
    public let rate: Decimal

    public init(date: Date, currency: String, rate: Decimal) {
        self.date = date
        self.currency = currency
        self.rate = rate
    }
}

/// Where official rates come from. The FX module implements it over the network; `App` supplies
/// it. Everything else in Bade stays offline, and a source that cannot answer returns nothing
/// rather than failing — the markup is the only thing that goes missing.
public protocol OfficialRateSource: Sendable {
    /// Rates for these currencies on these days.
    ///
    /// Days rather than a span because NBG publishes one day per request and has no range
    /// parameter. What can be hidden is hidden: the request never names a currency, and a day
    /// fetched once is cached and never asked for again.
    func rates(for currencies: Set<String>, on dates: Set<Date>) async -> [OfficialRate]
}

/// Default collaborator, and the shape of the app with the network switched off.
public struct NoOfficialRates: OfficialRateSource {
    public init() {}

    public func rates(for currencies: Set<String>, on dates: Set<Date>) async -> [OfficialRate] {
        []
    }
}
