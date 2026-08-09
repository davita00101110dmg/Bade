import Core
import Foundation

/// One subscription as the list renders it, with its cost already resolved into the display
/// currency where a rate exists.
public struct SubscriptionRow: Equatable, Identifiable, Sendable {
    public let subscription: Subscription
    /// Monthly cost in the display currency, or `nil` when no rate covers this charge.
    public let converted: Decimal?

    public var id: UUID { subscription.id }

    /// Anything unconvertible sorts last rather than pretending to be free.
    var sortableMonthly: Decimal { converted ?? .leastFiniteMagnitude }

    /// The charge itself, in whatever currency it is billed — the design's "$20.00".
    public var billed: Decimal { subscription.amount }

    public func showsBilledPrice(against currency: String) -> Bool {
        subscription.currency != currency
    }

    public func displayAmount(in currency: String) -> Decimal {
        converted ?? subscription.monthlyAmount
    }

    public func displayCurrency(_ currency: String) -> String {
        converted == nil ? subscription.currency : currency
    }

    /// The monogram the brief asks for where no logo exists: consistency over coverage.
    public var monogram: String {
        subscription.merchant.first.map { String($0).uppercased() } ?? "?"
    }
}
