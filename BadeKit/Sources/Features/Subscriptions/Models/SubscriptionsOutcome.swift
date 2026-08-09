import Core
import Foundation

/// Every way this screen hands control back, so the parent handles them in one exhaustive place.
public enum SubscriptionsOutcome: Equatable, Sendable {
    case importStatement
    /// Nothing is stored any more, so the root belongs back on Welcome.
    case dataCleared
}
