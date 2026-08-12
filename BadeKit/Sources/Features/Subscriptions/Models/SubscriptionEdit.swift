import Core
import Foundation

/// What the form sheet is showing: the subscription being amended, or nothing at all when it is a
/// new one. Identified rather than a bare optional, because a sheet has to be told what changed.
public struct SubscriptionEdit: Identifiable, Equatable, Sendable {
    public let subscription: Subscription?

    public init(_ subscription: Subscription?) {
        self.subscription = subscription
    }

    public var id: String { subscription?.id.uuidString ?? "new" }
}
