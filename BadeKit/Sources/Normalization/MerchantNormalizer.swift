import Core
import Foundation

/// Spec §6 tier 1: deterministic, always available, and sufficient on its own. The Foundation
/// Models tier is an enhancement layered on top later and is never required.
public struct MerchantNormalizer: Sendable {
    private let directory: any MerchantDirectory
    private let rules: [any MerchantCleaningRule] = [
        LocationStripper(), ReferenceTokenStripper(), ProcessorPrefixStripper(),
        DomainStripper(), WhitespaceTidier(),
    ]

    public init(directory: any MerchantDirectory = EmptyMerchantDirectory()) {
        self.directory = directory
    }

    public func normalize(_ transactions: [RawTransaction]) -> [NormalizedTransaction] {
        transactions.map(normalize)
    }

    public func normalize(_ transaction: RawTransaction) -> NormalizedTransaction {
        let cleaned = rules.reduce(transaction.rawDescription) { $1.apply(to: $0) }

        if let canonical = directory.canonicalMerchant(for: cleaned) {
            return NormalizedTransaction(
                raw: transaction, merchant: canonical, merchantConfidence: Confidence.catalog)
        }
        let usable = cleaned.isEmpty ? transaction.rawDescription : cleaned
        return NormalizedTransaction(
            raw: transaction,
            merchant: usable,
            merchantConfidence: usable == transaction.rawDescription
                ? Confidence.unchanged : Confidence.cleaned
        )
    }

    private enum Confidence {
        static let catalog = 1.0
        static let cleaned = 0.6
        static let unchanged = 0.3
    }
}
