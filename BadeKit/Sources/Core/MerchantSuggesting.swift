/// Names to offer while a subscription is being typed in by hand. The form depends on this, never
/// on `Catalog` itself; `App` supplies the implementation.
public protocol MerchantSuggesting: Sendable {
    func suggestedMerchants(matching text: String) -> [String]
}

/// Default collaborator so the form runs with no catalog wired in.
public struct NoMerchantSuggestions: MerchantSuggesting {
    public init() {}

    public func suggestedMerchants(matching text: String) -> [String] { [] }
}
