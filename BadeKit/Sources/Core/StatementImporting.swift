import Foundation

/// What one import produced. Rates come from the statement itself, so totals can span currencies.
public struct ImportResult: Equatable, Sendable {
    public let detected: [DetectedSubscription]
    public let rates: RateBook
    public let transactionCount: Int

    public init(detected: [DetectedSubscription], rates: RateBook, transactionCount: Int) {
        self.detected = detected
        self.rates = rates
        self.transactionCount = transactionCount
    }
}

/// Features depend on this, never on the parsing, normalisation or detection modules;
/// `App` composes the real pipeline. Statement bytes stay in memory and are never written (§10).
public protocol StatementImporting: Sendable {
    func detectSubscriptions(in statement: Data) async throws -> ImportResult
}
