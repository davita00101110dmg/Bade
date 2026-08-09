import Foundation

/// A subscription the user has confirmed. Distinct from `DetectedSubscription`: it has an
/// identity, survives re-imports, and can be cancelled.
public struct Subscription: Equatable, Sendable, Codable, Identifiable {
    public let id: UUID
    public var merchant: String
    public var amount: Decimal
    public var isVariableAmount: Bool
    /// ISO 4217.
    public var currency: String
    public var cadence: Cadence
    public var firstChargeDate: Date
    public var lastChargeDate: Date
    public var nextChargeDate: Date
    public var occurrenceCount: Int
    public var priceChanges: [PriceChange]
    public var isActive: Bool
    public var confidence: Confidence

    public init(
        id: UUID = UUID(),
        merchant: String,
        amount: Decimal,
        isVariableAmount: Bool = false,
        currency: String,
        cadence: Cadence,
        firstChargeDate: Date,
        lastChargeDate: Date,
        nextChargeDate: Date,
        occurrenceCount: Int,
        priceChanges: [PriceChange] = [],
        isActive: Bool = true,
        confidence: Confidence
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.isVariableAmount = isVariableAmount
        self.currency = currency
        self.cadence = cadence
        self.firstChargeDate = firstChargeDate
        self.lastChargeDate = lastChargeDate
        self.nextChargeDate = nextChargeDate
        self.occurrenceCount = occurrenceCount
        self.priceChanges = priceChanges
        self.isActive = isActive
        self.confidence = confidence
    }

    /// What the user confirms at the end of the pipeline (§3).
    public init(confirming detected: DetectedSubscription, id: UUID = UUID()) {
        let dates = detected.occurrences.map(\.date).sorted()
        self.init(
            id: id,
            merchant: detected.merchant,
            amount: detected.amount,
            isVariableAmount: detected.isVariableAmount,
            currency: detected.currency,
            cadence: detected.cadence,
            firstChargeDate: dates.first ?? detected.nextChargeDate,
            lastChargeDate: dates.last ?? detected.nextChargeDate,
            nextChargeDate: detected.nextChargeDate,
            occurrenceCount: detected.occurrences.count,
            priceChanges: detected.priceChanges,
            confidence: detected.confidence
        )
    }

    /// Identity across imports: the same service billed the same way, whatever the id.
    public var matchKey: String { "\(merchant)|\(currency)|\(cadence.rawValue)" }
}
