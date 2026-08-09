import Core
import Foundation

public protocol StatementParser: Sendable {
    static var identifier: String { get }
    static var displayName: String { get }
    func canParse(_ text: String) -> Bool
    func parse(_ text: String) throws -> [RawTransaction]
}

public enum StatementParsingError: Error, Equatable {
    case unrecognisedFormat
    /// A statement that yields almost nothing is a parser failure, not an empty account (§5).
    case suspiciouslyFewTransactions(found: Int)
}
