import Core
import Foundation

public struct BundledCatalog: SubscriptionCatalog {
    private let entries: [CatalogEntry]

    public init(entries: [CatalogEntry] = MerchantSeed.entries) {
        self.entries = entries
    }

    public func match(merchant: String, amount: Decimal, currency: String) -> CatalogMatch {
        guard let entry = entry(for: merchant) else { return .none }

        let published = entry.pricePoints.first {
            $0.currency == currency && AmountTolerance.matches($0.amount, amount)
        }
        guard let published else { return .merchant(typicalCadence: entry.typicalCadence) }
        return .pricePoint(cadence: published.cadence)
    }

    /// Exact match only. Substring matching turned "ZOOMMER" into Zoom and "OPEN AIR" into
    /// ChatGPT; a recurring charge is caught by interval detection anyway, so precision wins.
    public func entry(for merchant: String) -> CatalogEntry? {
        let folded = MerchantName.folded(merchant)
        guard !folded.isEmpty else { return nil }
        return entries.first { $0.matchTokens.contains(folded) }
    }
}
