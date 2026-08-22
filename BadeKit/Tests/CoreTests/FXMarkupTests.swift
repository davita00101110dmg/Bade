import Foundation
import Testing

@testable import Core

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

private func decimal(_ value: String) -> Decimal { Decimal(string: value)! }

/// Billed in lari, with a pair of rates printed beside it anyway — the shape a real BOG statement
/// produced on all 22 of its conversions. The merchant is abroad so the scheme settles through
/// dollars, but the amount was fixed in lari and the cardholder paid exactly the sticker price.
private func billedInLari(
    _ iso: String = "2026-07-20", charged: String = "14.99", bank: String = "2.6371",
    scheme: String? = "2.5979"
) -> Charge {
    Charge(
        date: day(iso), amount: decimal(charged), currency: "GEL",
        conversion: CurrencyConversion(
            from: "USD", to: "GEL", bankRate: decimal(bank),
            schemeRate: scheme.map(decimal)))
}

/// A genuinely foreign charge: priced in dollars, settled into a lari account at the bank's rate.
/// The only shape where a conversion actually cost the cardholder anything.
private func billedInDollars(
    _ iso: String = "2026-07-20", charged: String = "12.99", bank: String = "2.72",
    scheme: String? = "2.6315"
) -> Charge {
    Charge(
        date: day(iso), amount: decimal(charged), currency: "USD",
        conversion: CurrencyConversion(
            from: "USD", to: "GEL", bankRate: decimal(bank),
            schemeRate: scheme.map(decimal)))
}

private func settledAtHome(charged: String = "12.99", bank: String = "2.72") -> Charge {
    Charge(
        date: day("2026-07-20"), amount: decimal(charged), currency: "USD",
        conversion: CurrencyConversion(from: "USD", to: "GEL", bankRate: decimal(bank)))
}

private func subscription(_ charges: [Charge], cadence: Cadence = .monthly) -> Subscription {
    Subscription(
        merchant: "Spotify", amount: decimal("15.20"), currency: "GEL", cadence: cadence,
        firstChargeDate: day("2026-01-20"), lastChargeDate: day("2026-07-20"),
        nextChargeDate: day("2026-08-20"), charges: charges, confidence: .confident)
}

@Suite("What the bank's rate cost")
struct FXMarkupTests {
    /// The bug this suite was written around, inverted by a real statement.
    ///
    /// A lari-billed charge with rates printed beside it was read as a dollar price paid out of a
    /// dollar balance: the amount was divided by the bank's rate into a sticker nobody was quoted,
    /// multiplied back at the scheme's, and the difference reported as a loss. It came out at 1.5%
    /// every time, which read as a finding about the bank and was really `(bank − scheme) / scheme`
    /// — arithmetic about the two rates, not about the money.
    ///
    /// Setanta costs 14.99 GEL. The statement says 14.99 GEL was debited. Nothing was converted.
    @Test func alariChargeWithRatesPrintedBesideItHasNoMarkup() {
        #expect(billedInLari().markup(against: decimal("2.5979"), reference: .cardScheme) == nil)
        #expect(billedInLari().wasConverted == false)
    }

    /// What a conversion actually costs, when one actually happened: the two rates, times the
    /// amount. No division, and no sticker price to guess at.
    @Test func adollarChargeIsConvertedAtTheBankRateAndJudgedAgainstTheScheme() throws {
        let markup = try #require(
            billedInDollars().markup(against: decimal("2.6315"), reference: .cardScheme))

        #expect(markup.charged == decimal("12.99"), "the sticker, as printed")
        #expect(markup.chargedCurrency == "USD")
        #expect(markup.paidCurrency == "GEL")
        #expect(markup.paid == decimal("12.99") * decimal("2.72"))
        #expect(markup.fair == decimal("12.99") * decimal("2.6315"))
        #expect(markup.extra > 0)
    }

    @Test func adollarChargeSettledInLariIsCountedInLari() throws {
        let markup = try #require(settledAtHome().markup(against: decimal("2.61"), reference: .official))

        #expect(markup.chargedCurrency == "USD")
        #expect(markup.paidCurrency == "GEL")
        #expect(markup.paid == decimal("35.3328"))
        #expect(markup.fair == decimal("33.9039"))
        #expect(markup.extra == decimal("1.4289"))
    }

    /// The gap between the two printed rates, which is what a real conversion costs.
    @Test func thefractionIsTheSpreadBetweenTheTwoRates() throws {
        let markup = try #require(
            billedInDollars().markup(against: decimal("2.6315"), reference: .cardScheme))
        let fraction = try #require(markup.fraction)

        #expect(fraction > decimal("0.033") && fraction < decimal("0.035"))
    }

    /// A bank rate above the reference means more lari for the same sticker, which is the markup;
    /// below it means the bank beat the reference, and that is shown as it is.
    @Test func abankThatBeatsTheReferenceShowsANegativeMarkup() throws {
        let markup = try #require(
            billedInDollars(bank: "2.60", scheme: "2.70").markup(
                against: decimal("2.70"), reference: .cardScheme))

        #expect(markup.extra < 0)
    }

    @Test(arguments: [(Cadence.monthly, 12), (.annual, 1), (.weekly, 52), (.quarterly, 4)])
    func annualisingMultipliesByAyearOfCharges(_ cadence: Cadence, _ times: Int) throws {
        let markup = try #require(
            billedInDollars().markup(against: decimal("2.6315"), reference: .cardScheme))

        #expect(markup.annualised(at: cadence) == markup.extra * Decimal(times))
    }

    @Test(arguments: ["0", "-1"])
    func anonsenseReferenceRateIsRefusedRatherThanDividedBy(_ rate: String) {
        #expect(billedInDollars().markup(against: decimal(rate), reference: .cardScheme) == nil)
    }

    @Test func achargeThatWasNeverConvertedHasNoMarkup() {
        let plain = Charge(date: day("2026-07-20"), amount: 15.2, currency: "GEL", conversion: nil)

        #expect(plain.markup(against: decimal("2.59"), reference: .cardScheme) == nil)
    }

    /// Neither side of the conversion matches the charge: something is wrong, and nothing is
    /// better than a number pointing the wrong way.
    @Test func achargeInAThirdCurrencyIsRefused() {
        let odd = Charge(
            date: day("2026-07-20"), amount: 10, currency: "EUR",
            conversion: CurrencyConversion(from: "USD", to: "GEL", bankRate: 2.63))

        #expect(odd.markup(against: decimal("2.60"), reference: .cardScheme) == nil)
    }
}

@Suite("Choosing what to judge the bank against")
struct SubscriptionMarkupTests {
    private let official = [OfficialRate(date: day("2026-07-20"), currency: "USD", rate: 2.6327)]

    /// The statement's own scheme rate wins: it needs no network and it is the gap the bank earned.
    @Test func theschemeRateIsPreferredWhenTheStatementPrintsIt() throws {
        let markup = try #require(
            subscription([billedInDollars()]).markup(against: official, calendar: utc))

        #expect(markup.reference == .cardScheme)
    }

    @Test func theofficialRateIsTheFallback() throws {
        let charge = billedInDollars(scheme: nil)
        let markup = try #require(subscription([charge]).markup(against: official, calendar: utc))

        #expect(markup.reference == .official)
    }

    @Test func withNeitherRateThereIsNoMarkup() {
        let charge = billedInDollars(scheme: nil)

        #expect(subscription([charge]).markup(against: [], calendar: utc) == nil)
    }

    @Test func itusesTheNewestConvertedCharge() throws {
        let subject = subscription([
            billedInDollars("2026-06-20", charged: "9.99", bank: "2.6505", scheme: "2.6150"),
            billedInDollars("2026-07-20"),
        ])

        #expect(try #require(subject.markup(calendar: utc)).charged == decimal("12.99"))
    }

    @Test func nothingConvertedIsSaidPlainlyRatherThanShownAsZero() {
        let plain = Charge(date: day("2026-07-20"), amount: 15.2, currency: "GEL", conversion: nil)
        let subject = subscription([plain])

        #expect(subject.markup(against: official, calendar: utc) == nil)
        #expect(subject.isPaidWithoutConversion)
    }

    @Test func asubscriptionWithNoChargesIsNotClaimedToBeUnconverted() {
        #expect(subscription([]).isPaidWithoutConversion == false)
    }
}
