/// Resolves a cleaned merchant string to its canonical brand name (spec §6 tier 1, step 2).
public protocol MerchantDirectory: Sendable {
    func canonicalMerchant(for description: String) -> String?
}

/// Default collaborator so normalization runs with no catalog wired in.
public struct EmptyMerchantDirectory: MerchantDirectory {
    public init() {}

    public func canonicalMerchant(for description: String) -> String? { nil }
}
