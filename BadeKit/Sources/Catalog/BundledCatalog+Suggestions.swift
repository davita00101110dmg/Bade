import Core

extension BundledCatalog: MerchantSuggesting {
    /// Brands that start with what has been typed come before brands that merely contain it, so
    /// "app" offers Apple before Snapchat. Capped, because a list longer than the field it sits
    /// under stops being a shortcut, and a name typed in full suggests nothing.
    public func suggestedMerchants(matching text: String) -> [String] {
        let typed = MerchantName.folded(text)
        guard !typed.isEmpty else { return [] }

        var beginning: [String] = []
        var containing: [String] = []
        for entry in entries {
            guard let token = entry.matchTokens.first(where: { $0.contains(typed) }), token != typed
            else { continue }
            if token.hasPrefix(typed) {
                beginning.append(entry.merchant)
            } else {
                containing.append(entry.merchant)
            }
        }
        return Array((beginning + containing).prefix(Self.suggestionLimit))
    }

    private static let suggestionLimit = 5
}
