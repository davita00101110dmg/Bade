import Foundation

/// One charge of a confirmed subscription, kept so its history outlives the import that found it.
///
/// Deliberately not a `RawTransaction`: the statement's own text — the description, the source
/// line, the merchant's address — is dropped here and never stored. What survives is the money,
/// the day, and what the bank did to convert it (§10, constraint 3).
public struct Charge: Equatable, Sendable, Codable {
    public let date: Date
    public let amount: Decimal
    /// ISO 4217.
    public let currency: String
    /// Present when the bank converted this charge; the source of the markup §8 reports.
    public let conversion: CurrencyConversion?

    public init(date: Date, amount: Decimal, currency: String, conversion: CurrencyConversion?) {
        self.date = date
        self.amount = amount
        self.currency = currency
        self.conversion = conversion
    }

    public init(_ transaction: RawTransaction) {
        self.init(
            date: transaction.date, amount: transaction.amount, currency: transaction.currency,
            conversion: transaction.conversion)
    }
}
