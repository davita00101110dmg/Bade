import Core
import Foundation

public struct BundledCatalog: SubscriptionCatalog {
    let entries: [CatalogEntry]
    /// Token to the earliest entry claiming it. Built once, because `matchTokens` folds every
    /// alias afresh on each access: scanning 450 entries per transaction cost a second on a
    /// 770-charge statement, which reads on screen as a progress bar that will not start.
    private let positions: [String: Int]

    public init(entries: [CatalogEntry] = MerchantSeed.entries) {
        self.entries = entries
        var positions: [String: Int] = [:]
        for (position, entry) in entries.enumerated() {
            // First wins, so an earlier entry still shadows a later one exactly as a scan did.
            for token in entry.matchTokens where positions[token] == nil {
                positions[token] = position
            }
        }
        self.positions = positions
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
        if let whole = positions[folded] { return entries[whole] }

        return MerchantName.words(merchant).compactMap { positions[$0] }.min().map { entries[$0] }
    }
}
