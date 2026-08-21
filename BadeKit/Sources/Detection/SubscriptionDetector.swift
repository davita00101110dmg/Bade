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

    /// Charges at one merchant, in one currency, before this many are just shopping.
    private static let minimumRepeats = 3

    public func detect(_ transactions: [NormalizedTransaction]) -> [DetectedSubscription] {
        analyse(transactions).subscriptions
    }

    /// What was found, and what repeated often enough to be worth asking about. One pass: the
    /// grouping either side of the question is the same work.
    public func analyse(_ transactions: [NormalizedTransaction]) -> DetectionOutcome {
        guard let statementEnd = transactions.map(\.raw.date).max() else { return .empty }
        let recurring = deduplicator.deduplicate(transactions)
            .filter { MerchantCategory.canRecur($0.raw) }

        var subscriptions: [DetectedSubscription] = []
        var candidates: [RepeatCandidate] = []
        for (account, charges) in Dictionary(grouping: recurring, by: Account.init)
            .sorted(by: { $0.key < $1.key })
        {
            let found = grouper.clusters(for: charges).compactMap {
                subscription(for: account, from: $0, statementEnd: statementEnd)
            }
            subscriptions += found
            // Only when nothing was found: a merchant already reported needs no second answer.
            guard found.isEmpty, charges.count >= Self.minimumRepeats else { continue }
            candidates.append(Self.candidate(for: account, from: charges))
        }
        return DetectionOutcome(subscriptions: subscriptions, candidates: candidates)
    }

    private static func candidate(for account: Account, from charges: [NormalizedTransaction])
        -> RepeatCandidate
    {
        let latest = charges.max { $0.raw.date < $1.raw.date }
        return RepeatCandidate(
            merchant: account.merchant,
            currency: account.currency,
            amount: latest?.raw.amount ?? 0,
            occurrences: charges.map(\.raw).sorted { $0.date < $1.date })
    }

    private func subscription(
        for account: Account, from cluster: ChargeCluster, statementEnd: Date
    ) -> DetectedSubscription? {
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
            priceChanges: history.priceChanges,
            hasEnded: SubscriptionLapse.hasLapsed(
                since: latest.date, cadence: cadence, statementEnd: statementEnd)
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
