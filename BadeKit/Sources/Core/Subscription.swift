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
    /// Every charge behind this subscription. Empty for one entered by hand, which has a price
    /// and a rhythm but no history yet.
    public var charges: [Charge]
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
        charges: [Charge] = [],
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
        self.charges = charges
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
            charges: detected.occurrences.map(Charge.init),
            priceChanges: detected.priceChanges,
            confidence: detected.confidence
        )
    }

    /// Derived rather than stored, so it can never disagree with the history it counts.
    public var occurrenceCount: Int { charges.count }

    /// Identity across imports: the same service billed the same way, whatever the id.
    public var matchKey: String { "\(merchant)|\(currency)|\(cadence.rawValue)" }
}
