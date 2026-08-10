import Core
import Foundation

/// One month of a subscription's history, sized against the tallest month beside it.
public struct ChargeBar: Equatable, Identifiable, Sendable {
    public let month: Date
    public let amount: Decimal
    /// Height relative to the tallest bar. A ratio, not money, so a `Double` is the right type.
    public let fraction: Double
    /// The change that landed this month, if one did. Kept whole rather than reduced to a flag,
    /// because a rise and a fall are not the same news.
    public let priceChange: PriceChange?

    public var id: Date { month }
    public var isEmpty: Bool { amount == 0 }
    public var isPriceRise: Bool { priceChange.map { $0.to > $0.from } ?? false }
}
