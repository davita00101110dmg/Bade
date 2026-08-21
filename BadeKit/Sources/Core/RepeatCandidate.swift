import Foundation

/// A merchant charged again and again that no cadence explained.
///
/// Not a subscription: the engine looked and could not find a rhythm, and inventing one would put a
/// figure on screen it cannot justify. Not something to discard either — the person who paid knows
/// what the statement cannot say, and on a real year of spending there are around a dozen of these
/// against a handful of detections. Asking is the only honest way to close that gap.
public struct RepeatCandidate: Equatable, Sendable, Codable, Identifiable {
    public let merchant: String
    /// ISO 4217.
    public let currency: String
    /// The most recent charge, which is what a form opens with.
    public let amount: Decimal
    public let occurrences: [RawTransaction]

    public init(merchant: String, currency: String, amount: Decimal, occurrences: [RawTransaction]) {
        self.merchant = merchant
        self.currency = currency
        self.amount = amount
        self.occurrences = occurrences
    }

    /// A merchant is one candidate per currency, which is also what makes it stable across a list.
    public var id: String { "\(merchant)|\(currency)" }

    public var lastChargeDate: Date {
        occurrences.map(\.date).max() ?? .distantPast
    }
}
