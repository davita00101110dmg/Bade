import Core
import Foundation

/// Spec §7. Pure: no I/O, no network, no LLM.
public struct SubscriptionDetector: Sendable {
    private let catalog: any SubscriptionCatalog
    private let deduplicator = TransactionDeduplicator()
    private let grouper = ChargeGrouper()
    private let cadenceResolver = CadenceResolver()
    private let amountAnalyzer = AmountHistoryAnalyzer()
    private let scorer = ConfidenceScorer()

    public init(catalog: any SubscriptionCatalog = EmptyCatalog()) {
        self.catalog = catalog
    }

    public func detect(_ transactions: [NormalizedTransaction]) -> [DetectedSubscription] {
        Dictionary(grouping: deduplicator.deduplicate(transactions), by: Account.init)
            .sorted { $0.key < $1.key }
            .flatMap { account, charges in
                grouper.clusters(for: charges).compactMap { subscription(for: account, from: $0) }
            }
    }

    private func subscription(for account: Account, from cluster: ChargeCluster) -> DetectedSubscription? {
        let latest = cluster.last.raw
        let match = catalog.match(
            merchant: account.merchant, amount: latest.amount, currency: account.currency)

        guard let cadence = cadence(for: cluster, match: match),
            let confidence = scorer.confidence(occurrences: cluster.charges.count, catalog: match)
        else { return nil }

        let occurrences = cluster.occurrences
        let history = amountAnalyzer.history(of: occurrences)
        return DetectedSubscription(
            merchant: account.merchant,
            amount: latest.amount,
            isVariableAmount: history.isVariable,
            currency: account.currency,
            cadence: cadence,
            occurrences: occurrences,
            nextChargeDate: ChargeCalendar.date(after: latest.date, cadence: cadence),
            confidence: confidence,
            priceChanges: history.priceChanges
        )
    }

    /// Observed intervals outrank the catalog; the catalog only speaks when there is no interval yet.
    private func cadence(for cluster: ChargeCluster, match: CatalogMatch) -> Cadence? {
        cluster.charges.count >= 2 ? cadenceResolver.cadence(for: cluster.dates) : match.cadence
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
