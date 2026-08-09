import Core
import Foundation

/// Spec §7. Pure: no I/O, no network, no LLM.
public struct SubscriptionDetector: Sendable {
    private let deduplicator = TransactionDeduplicator()
    private let grouper = ChargeGrouper()
    private let cadenceResolver = CadenceResolver()
    private let amountAnalyzer = AmountHistoryAnalyzer()
    private let scorer = ConfidenceScorer()

    public init() {}

    public func detect(_ transactions: [NormalizedTransaction]) -> [DetectedSubscription] {
        Dictionary(grouping: deduplicator.deduplicate(transactions), by: Account.init)
            .sorted { $0.key < $1.key }
            .flatMap { account, charges in
                grouper.clusters(for: charges).compactMap { subscription(for: account, from: $0) }
            }
    }

    private func subscription(for account: Account, from cluster: ChargeCluster) -> DetectedSubscription? {
        guard let cadence = cadenceResolver.cadence(for: cluster.dates),
            let confidence = scorer.confidence(forOccurrences: cluster.charges.count)
        else { return nil }

        let occurrences = cluster.occurrences
        let history = amountAnalyzer.history(of: occurrences)
        return DetectedSubscription(
            merchant: account.merchant,
            amount: cluster.last.raw.amount,
            isVariableAmount: history.isVariable,
            currency: account.currency,
            cadence: cadence,
            occurrences: occurrences,
            nextChargeDate: ChargeCalendar.date(after: cluster.last.raw.date, cadence: cadence),
            confidence: confidence,
            priceChanges: history.priceChanges
        )
    }
}

/// Currency joins the key so a merchant billing in two currencies never merges into one subscription.
private struct Account: Hashable, Comparable {
    let merchant: String
    let currency: String

    init(_ transaction: NormalizedTransaction) {
        merchant = transaction.merchant
        currency = transaction.raw.currency
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.merchant, lhs.currency) < (rhs.merchant, rhs.currency)
    }
}
