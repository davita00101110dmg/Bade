import Core
import Foundation

/// One subscription as the list renders it, with its cost already resolved into the display
/// currency where a rate exists.
public struct SubscriptionRow: Equatable, Identifiable, Sendable {
    public let subscription: Subscription
    /// Monthly cost in the display currency, or `nil` when no rate covers this charge.
    public let converted: Decimal?
    /// What is next as of today. A statement that ended before a charge was due leaves the stored
    /// date in the past, and a past date is neither an answer nor a sort key.
    public let nextCharge: Date

    public var id: UUID { subscription.id }

    /// Anything unconvertible sorts last rather than pretending to be free.
    var sortableMonthly: Decimal { converted ?? .leastFiniteMagnitude }

    /// The charge itself, in whatever currency it is billed — the design's "$20.00".
    public var billed: Decimal { subscription.amount }

    /// A currency the list is not totalling in, or a cadence the list is not showing — either way
    /// the figure on the right is not what anybody is charged, and the real price has to be said.
    /// Cadence used to be missing here, so a yearly subscription in the display currency showed a
    /// twelfth of its price and a date, and its actual cost appeared nowhere on the screen.
    public func showsBilledPrice(against currency: String) -> Bool {
        subscription.currency != currency || subscription.cadence != .monthly
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
