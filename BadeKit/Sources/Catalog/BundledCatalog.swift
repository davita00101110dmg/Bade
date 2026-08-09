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

    /// Longest matching token wins, so "GitHub Copilot" beats "GitHub" and "Dropbox" beats "Box".
    public func entry(for merchant: String) -> CatalogEntry? {
        let folded = MerchantName.folded(merchant)
        guard !folded.isEmpty else { return nil }

        var best: (entry: CatalogEntry, length: Int)?
        for entry in entries {
            let matched = entry.matchTokens.filter { !$0.isEmpty && folded.contains($0) }
            guard let length = matched.map(\.count).max(), length > best?.length ?? 0 else { continue }
            best = (entry, length)
        }
        return best?.entry
    }
}
