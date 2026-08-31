import Core
import Foundation

/// Every way this screen hands control back, so the parent handles them in one exhaustive place.
public enum SubscriptionsOutcome: Equatable, Sendable {
    case importStatement
    /// Nothing is stored any more, so the root belongs back on Welcome.
    case dataCleared
    /// How the list is ordered is a preference like any other, and only the root can store one.
    /// Without this it was the single setting the app forgot on every launch.
    case sortChanged(SubscriptionSort)
}
