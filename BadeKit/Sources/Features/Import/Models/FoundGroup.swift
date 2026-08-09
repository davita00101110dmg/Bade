import Core
import Foundation

/// Detection can return several subscriptions that are indistinguishable on screen — a merchant
/// like Apple bills many one-off charges at the same price. They collapse into one row.
public struct FoundGroup: Equatable, Identifiable, Sendable {
    public let merchant: String
    public let amount: Decimal
    public let currency: String
    public let count: Int

    public var id: String { "\(merchant)|\(amount)|\(currency)" }
}

extension Collection<DetectedSubscription> {
    /// Groups look-alikes while keeping discovery order, so rows never reshuffle as they arrive.
    public var foundGroups: [FoundGroup] {
        var order: [String] = []
        var counts: [String: FoundGroup] = [:]
        for subscription in self {
            let key = "\(subscription.merchant)|\(subscription.amount)|\(subscription.currency)"
            if let existing = counts[key] {
                counts[key] = FoundGroup(
                    merchant: existing.merchant, amount: existing.amount,
                    currency: existing.currency, count: existing.count + 1)
            } else {
                order.append(key)
                counts[key] = FoundGroup(
                    merchant: subscription.merchant, amount: subscription.amount,
                    currency: subscription.currency, count: 1)
            }
        }
        return order.compactMap { counts[$0] }
    }
}
