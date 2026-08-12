import Core
import Foundation
import SwiftData

/// SwiftData never leaves this module; everything outside speaks in `Subscription`.
@Model
final class SubscriptionRecord {
    #Index<SubscriptionRecord>([\.matchKey])

    @Attribute(.unique) var id: UUID
    var merchant: String
    var amount: Decimal
    var isVariableAmount: Bool
    var currency: String
    var cadenceRaw: String
    var firstChargeDate: Date
    var lastChargeDate: Date
    var nextChargeDate: Date
    var charges: [Charge]
    var priceChanges: [PriceChange]
    var isActive: Bool
    var confidenceRaw: String
    var matchKey: String

    init(_ subscription: Subscription) {
        id = subscription.id
        merchant = subscription.merchant
        amount = subscription.amount
        isVariableAmount = subscription.isVariableAmount
        currency = subscription.currency
        cadenceRaw = subscription.cadence.rawValue
        firstChargeDate = subscription.firstChargeDate
        lastChargeDate = subscription.lastChargeDate
        nextChargeDate = subscription.nextChargeDate
        charges = subscription.charges
        priceChanges = subscription.priceChanges
        isActive = subscription.isActive
        confidenceRaw = subscription.confidence.rawValue
        matchKey = subscription.matchKey
    }

    /// `matchKey` is deliberately absent: identity is set once, by whatever created the row, so
    /// renaming a subscription cannot hide it from the next import of the same statement.
    func update(from subscription: Subscription) {
        merchant = subscription.merchant
        amount = subscription.amount
        isVariableAmount = subscription.isVariableAmount
        currency = subscription.currency
        cadenceRaw = subscription.cadence.rawValue
        firstChargeDate = subscription.firstChargeDate
        lastChargeDate = subscription.lastChargeDate
        nextChargeDate = subscription.nextChargeDate
        charges = subscription.charges
        priceChanges = subscription.priceChanges
        isActive = subscription.isActive
        confidenceRaw = subscription.confidence.rawValue
    }

    var subscription: Subscription {
        Subscription(
            id: id,
            merchant: merchant,
            amount: amount,
            isVariableAmount: isVariableAmount,
            currency: currency,
            cadence: Cadence(rawValue: cadenceRaw) ?? .monthly,
            firstChargeDate: firstChargeDate,
            lastChargeDate: lastChargeDate,
            nextChargeDate: nextChargeDate,
            charges: charges,
            priceChanges: priceChanges,
            isActive: isActive,
            confidence: Confidence(rawValue: confidenceRaw) ?? .probable
        )
    }
}
