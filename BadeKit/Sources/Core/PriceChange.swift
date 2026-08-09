import Foundation

/// Recorded in-place; a price step never splits one subscription into two.
public struct PriceChange: Equatable, Sendable, Codable {
    public let date: Date
    public let from: Decimal
    public let to: Decimal

    public init(date: Date, from: Decimal, to: Decimal) {
        self.date = date
        self.from = from
        self.to = to
    }
}
