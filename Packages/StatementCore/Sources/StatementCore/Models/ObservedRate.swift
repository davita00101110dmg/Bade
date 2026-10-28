import Foundation

/// An exchange rate the statement itself recorded on a given day, from a conversion the account
/// holder actually made. Multiplying an amount in `from` by `rate` gives `to`.
///
/// These are what the bank charged rather than what anyone published, which is the number this
/// app exists to report — and reading them means a statement carrying its own conversions needs
/// no network call to be totalled in one currency (§8, constraint 2).
public struct ObservedRate: Equatable, Sendable, Codable {
    public let date: Date
    /// ISO 4217.
    public let from: String
    public let to: String
    public let rate: Decimal

    public init(date: Date, from: String, to: String, rate: Decimal) {
        self.date = date
        self.from = from
        self.to = to
        self.rate = rate
    }
}
