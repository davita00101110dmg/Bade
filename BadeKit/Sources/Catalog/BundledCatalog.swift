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
        if let published { return .pricePoint(cadence: published.cadence) }

        // Knowing the merchant is only evidence if the merchant sells nothing but subscriptions.
        return entry.sellsOneOffs ? .none : .merchant(typicalCadence: entry.typicalCadence)
    }

    /// Whole words, never substrings. Substring matching turned "ZOOMMER" into Zoom and "OPEN AIR"
    /// into ChatGPT, but matching the whole string missed every descriptor carrying an extra word —
    /// "ANTHROPIC* CLAUDE SUB" and "CLAUDE.AI SUBSCRIPTION" are both Claude. A word either is the
    /// brand or it is not: "ZOOMMER" is one word and it is not "zoom".
    public func entry(for merchant: String) -> CatalogEntry? {
        let folded = MerchantName.folded(merchant)
        guard !folded.isEmpty else { return nil }
        if let whole = entries.first(where: { $0.matchTokens.contains(folded) }) { return whole }

        let words = Set(MerchantName.words(merchant))
        return entries.first { $0.matchTokens.contains(where: words.contains) }
    }
}
