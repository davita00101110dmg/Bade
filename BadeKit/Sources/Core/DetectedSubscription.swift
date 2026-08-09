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

    public init(
        merchant: String,
        amount: Decimal,
        isVariableAmount: Bool = false,
        currency: String,
        cadence: Cadence,
        occurrences: [RawTransaction],
        nextChargeDate: Date,
        confidence: Confidence,
        priceChanges: [PriceChange]
    ) {
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
