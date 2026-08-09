import Foundation

public struct RawTransaction: Equatable, Sendable, Codable {
    public let date: Date
    public let rawDescription: String
    /// Always positive; debits only.
    public let amount: Decimal
    /// ISO 4217.
    public let currency: String
    /// Verbatim statement line, for debugging and golden tests.
    public let sourceLine: String

    public init(
        date: Date,
        rawDescription: String,
        amount: Decimal,
        currency: String,
        sourceLine: String
    ) {
        self.date = date
        self.rawDescription = rawDescription
        self.amount = amount
        self.currency = currency
        self.sourceLine = sourceLine
    }
}
