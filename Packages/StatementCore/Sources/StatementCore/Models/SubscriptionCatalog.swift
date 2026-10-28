import Foundation

/// What the catalog can tell detection about a charge (spec §7.5).
public enum CatalogMatch: Equatable, Sendable {
    case none
    /// Merchant is known, but this amount is not one of its published prices.
    case merchant(typicalCadence: Cadence)
    /// Amount sits on a published price point — enough to trust a single occurrence.
    case pricePoint(cadence: Cadence)

    public var cadence: Cadence? {
        switch self {
        case .none: nil
        case .merchant(let cadence), .pricePoint(let cadence): cadence
        }
    }
}

/// Detection depends on this, never on `Catalog` itself; `App` supplies the implementation.
public protocol SubscriptionCatalog: Sendable {
    func match(merchant: String, amount: Decimal, currency: String) -> CatalogMatch
}

/// Default collaborator so detection runs unchanged with no catalog wired in.
public struct EmptyCatalog: SubscriptionCatalog {
    public init() {}

    public func match(merchant: String, amount: Decimal, currency: String) -> CatalogMatch {
        .none
    }
}
