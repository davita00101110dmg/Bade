import Foundation

/// What a bank's own rate cost against a reference rate, for one charge (spec §8).
///
/// The bank's rate is never estimated — the statement prints it. What varies is what to judge it
/// against, and where the money is counted.
public struct FXMarkup: Equatable, Sendable {
    /// Which rate the bank's was judged against, because they are not equally authoritative and
    /// the screen has to say which one it used.
    public enum Reference: Equatable, Sendable {
        /// Printed on the statement beside the bank's own. Needs no network and is the gap the
        /// bank actually earned.
        case cardScheme
        /// The central bank's published rate for that day, fetched.
        case official
    }

    /// What the merchant charged, in the currency they charged it in.
    public let charged: Decimal
    public let chargedCurrency: String
    /// What actually left the account, and in which currency.
    public let paid: Decimal
    public let paidCurrency: String
    /// What would have left it at the reference rate.
    public let fair: Decimal
    public let reference: Reference

    public init(
        charged: Decimal, chargedCurrency: String, paid: Decimal, paidCurrency: String,
        fair: Decimal, reference: Reference
    ) {
        self.charged = charged
        self.chargedCurrency = chargedCurrency
        self.paid = paid
        self.paidCurrency = paidCurrency
        self.fair = fair
        self.reference = reference
    }

    /// The gap, in the currency the money left in. Negative when the bank beat the reference,
    /// which happens and is shown as it is rather than clamped away.
    public var extra: Decimal { paid - fair }

    public var fraction: Decimal? {
        guard fair > 0 else { return nil }
        return extra / fair
    }

    /// §8's headline: what this costs across a year at this cadence.
    public func annualised(at cadence: Cadence) -> Decimal {
        extra * Decimal(cadence.chargesPerYear)
    }
}

extension Cadence {
    /// How many times a year this bills. Whole numbers: every cadence divides the year evenly
    /// except weekly, which is 52 by convention rather than 52.18.
    public var chargesPerYear: Int {
        switch self {
        case .weekly: 52
        case .monthly: 12
        case .quarterly: 4
        case .semiannual: 2
        case .annual: 1
        }
    }
}

extension Charge {
    /// The markup on this charge, judged against `rate`.
    ///
    /// The money is always counted in the currency the account settled in, because that is what
    /// left it. The sticker price is not stored — a statement records what was debited — so it is
    /// recovered by dividing the settled amount by the rate the bank used.
    ///
    /// Which side of the conversion the amount is denominated in is read from the charge rather
    /// than assumed. Getting it backwards inverts the sign of every markup, which is worse than
    /// showing none.
    public func markup(against rate: Decimal, reference: FXMarkup.Reference) -> FXMarkup? {
        guard let conversion, rate > 0, conversion.bankRate > 0 else { return nil }

        if currency == conversion.to {
            let sticker = amount / conversion.bankRate
            return FXMarkup(
                charged: sticker, chargedCurrency: conversion.from,
                paid: amount, paidCurrency: currency,
                fair: sticker * rate, reference: reference)
        }
        guard currency == conversion.from else { return nil }
        return FXMarkup(
            charged: amount, chargedCurrency: currency,
            paid: amount * conversion.bankRate, paidCurrency: conversion.to,
            fair: amount * rate, reference: reference)
    }
}

extension Subscription {
    /// The markup on the most recent charge the bank converted.
    ///
    /// The card scheme's own rate is preferred when the statement printed it: it is the gap the
    /// bank actually earned, it needs no network, and it is available offline on the first run.
    /// The central bank's rate is the fallback for statements that print only one rate.
    public func markup(against official: [OfficialRate] = [], calendar: Calendar = .current)
        -> FXMarkup?
    {
        guard let charge = lastConvertedCharge, let conversion = charge.conversion else {
            return nil
        }
        if let scheme = conversion.schemeRate {
            return charge.markup(against: scheme, reference: .cardScheme)
        }
        guard
            let rate = official.first(where: {
                $0.currency == conversion.from
                    && calendar.isDate($0.date, inSameDayAs: charge.date)
            })
        else { return nil }
        return charge.markup(against: rate.rate, reference: .official)
    }

    /// The newest charge the bank actually converted. A charge paid from a balance already in its
    /// own currency never touched a rate, and has nothing to report.
    public var lastConvertedCharge: Charge? {
        charges.filter { $0.conversion != nil }.max { $0.date < $1.date }
    }

    /// Nothing was ever converted — paid from a balance in the currency it was charged in.
    public var isPaidWithoutConversion: Bool {
        !charges.isEmpty && lastConvertedCharge == nil
    }
}
