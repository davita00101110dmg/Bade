import Core
import Foundation

/// One notification: everything charging on a single day, and when to say so. A day rather than a
/// charge, because three charges landing together should be one thing to read, not three buzzes.
public struct ChargeReminder: Equatable, Sendable, Identifiable {
    public let chargeDate: Date
    public let fireDate: Date
    /// How many days before the charge this goes out, which is what the wording turns on.
    public let daysAhead: Int
    public let charges: [UpcomingCharge]

    public init(chargeDate: Date, fireDate: Date, daysAhead: Int, charges: [UpcomingCharge]) {
        self.chargeDate = chargeDate
        self.fireDate = fireDate
        self.daysAhead = daysAhead
        self.charges = charges
    }

    /// Stable across rescheduling: the same day always claims the same notification.
    public var id: String { "bade.reminder.\(Int(chargeDate.timeIntervalSince1970))" }

    public var merchants: [String] { charges.map(\.subscription.merchant) }

    /// The day's total, and only when every charge on it is in one currency — converting would
    /// need a rate, and a reminder is not the place to imply one.
    public var total: (amount: Decimal, currency: String)? {
        guard let currency = charges.first?.currency,
            charges.allSatisfy({ $0.currency == currency })
        else { return nil }
        return (charges.reduce(Decimal.zero) { $0 + $1.amount }, currency)
    }
}
