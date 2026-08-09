import Core
import Foundation

public protocol StatementParser: Sendable {
    static var identifier: String { get }
    static var displayName: String { get }
    func canParse(_ text: String) -> Bool
    func parse(_ text: String) throws -> [RawTransaction]
    /// Exchange rates the statement records separately from any purchase. A statement need not
    /// carry any, in which case cross-currency totals depend on §8's published rates instead.
    func exchangeRates(in text: String) -> [ObservedRate]
}

public enum StatementParsingError: Error, Equatable {
    case unrecognisedFormat
    /// A statement that yields almost nothing is a parser failure, not an empty account (§5).
    case suspiciouslyFewTransactions(found: Int)
}
