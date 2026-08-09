import Foundation

/// What one import produced. Rates come from the statement itself, so totals can span currencies.
public struct ImportResult: Equatable, Sendable {
    public let detected: [DetectedSubscription]
    public let rates: RateBook
    public let transactionCount: Int
    /// The span the statement covers, used to show progress through it.
    public let period: ClosedRange<Date>?

    public init(
        detected: [DetectedSubscription], rates: RateBook, transactionCount: Int,
        period: ClosedRange<Date>? = nil
    ) {
        self.detected = detected
        self.rates = rates
        self.transactionCount = transactionCount
        self.period = period
    }
}

/// What can go wrong importing, in terms a feature can present without knowing about parsers.
public enum ImportError: Error, Equatable, Sendable {
    case unreadableFile
    case unrecognisedFormat
    case tooFewTransactions
}

/// Features depend on this, never on the parsing, normalisation or detection modules;
/// `App` composes the real pipeline. Statement bytes stay in memory and are never written (§10).
public protocol StatementImporting: Sendable {
    func detectSubscriptions(in statement: Data) async throws -> ImportResult
}
