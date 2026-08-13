import Foundation

/// What the store said. `cancelled` is not a failure — the user changed their mind, and nothing
/// should be reported to them about it.
public enum ProPurchaseResult: Equatable, Sendable {
    case bought
    case cancelled
    case failed
}

/// The one-time unlock, as the app needs it: a price to show, an entitlement to read, and two ways
/// to acquire it. StoreKit lives behind this so every screen above stays testable.
public protocol ProPurchasing: Sendable {
    /// Localised and formatted by the store, so no price is ever written into Bade.
    func price() async -> String?
    func isEntitled() async -> Bool
    func buy() async -> ProPurchaseResult
    /// Nothing to restore is not an error; it answers whether anything was found.
    func restore() async -> Bool
    /// Entitlements arriving without a purchase — bought on another device, or an Ask to Buy
    /// approved hours later. Each is acknowledged as it appears.
    func entitlementChanges() -> AsyncStream<Bool>
}

/// Stands in wherever a screen is built without a store behind it: previews, tests, snapshots.
public struct NoPurchases: ProPurchasing {
    public init() {}

    public func price() async -> String? { nil }
    public func isEntitled() async -> Bool { false }
    public func buy() async -> ProPurchaseResult { .failed }
    public func restore() async -> Bool { false }
    public func entitlementChanges() -> AsyncStream<Bool> { AsyncStream { $0.finish() } }
}
