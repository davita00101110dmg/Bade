import Foundation

/// A recurring charge the detection engine found, before the user confirms it.
public struct DetectedSubscription: Equatable, Sendable, Codable {
    public let merchant: String
    /// Most recent charge when `isVariableAmount`.
    public let amount: Decimal
    public let isVariableAmount: Bool
    /// ISO 4217.
    public let currency: String
    public let cadence: Cadence
    public let occurrences: [RawTransaction]
    public let nextChargeDate: Date
    public let confidence: Confidence
    public let priceChanges: [PriceChange]
    /// The charges stopped before the statement did. Still a subscription, and still worth
    /// reporting — dropping it left the user unable to see a thing they had plainly been paying
    /// for, which is the opposite of what a spend tracker is for.
    public let hasEnded: Bool

    public init(
        merchant: String,
        amount: Decimal,
        isVariableAmount: Bool = false,
        currency: String,
        cadence: Cadence,
        occurrences: [RawTransaction],
        nextChargeDate: Date,
        confidence: Confidence,
        priceChanges: [PriceChange],
        hasEnded: Bool = false
    ) {
        self.hasEnded = hasEnded
        self.merchant = merchant
        self.amount = amount
        self.isVariableAmount = isVariableAmount
        self.currency = currency
        self.cadence = cadence
        self.occurrences = occurrences
        self.nextChargeDate = nextChargeDate
        self.confidence = confidence
        self.priceChanges = priceChanges
    }
}
