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

/// A lari price paid out of a dollar balance — the shape a real BOG statement produced.
private func paidFromBalance(
    _ iso: String = "2026-07-20", charged: String = "15.20", bank: String = "2.6315",
    scheme: String? = "2.5939"
) -> Charge {
    Charge(
        date: day(iso), amount: decimal(charged), currency: "GEL",
        conversion: CurrencyConversion(
            from: "USD", to: "GEL", bankRate: decimal(bank),
            schemeRate: scheme.map(decimal)))
}

/// The other direction: a dollar price settled into a lari account.
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
    /// What the statement records is the lari debited; the dollar sticker is recovered from it.
    /// The money is counted in lari, because lari is what left the account.
    @Test func thestickerIsRecoveredAndTheMoneyCountedWhereItLeft() throws {
        let markup = try #require(paidFromBalance().markup(against: decimal("2.5939"), reference: .cardScheme))

        #expect(markup.paid == decimal("15.20"), "what was debited")
        #expect(markup.paidCurrency == "GEL")
        #expect(markup.chargedCurrency == "USD")
        #expect(markup.charged == decimal("15.20") / decimal("2.6315"), "the sticker, recovered")
        #expect(markup.extra > 0, "the bank's rate cost more lari than the scheme's")
    }

    @Test func adollarChargeSettledInLariIsCountedInLari() throws {
        let markup = try #require(settledAtHome().markup(against: decimal("2.61"), reference: .official))

        #expect(markup.chargedCurrency == "USD")
        #expect(markup.paidCurrency == "GEL")
        #expect(markup.paid == decimal("35.3328"))
        #expect(markup.fair == decimal("33.9039"))
        #expect(markup.extra == decimal("1.4289"))
    }

    /// The measured spread on a real statement: about one and a half percent.
    @Test func thefractionMatchesWhatTheStatementImplies() throws {
        let markup = try #require(paidFromBalance().markup(against: decimal("2.5939"), reference: .cardScheme))
        let fraction = try #require(markup.fraction)

        #expect(fraction > decimal("0.014") && fraction < decimal("0.0146"))
    }

    /// A bank rate above the reference means more lari for the same sticker, which is the markup;
    /// below it means the bank beat the reference, and that is shown as it is.
    @Test func abankThatBeatsTheReferenceShowsANegativeMarkup() throws {
        let markup = try #require(
            paidFromBalance(bank: "2.60", scheme: "2.70").markup(
                against: decimal("2.70"), reference: .cardScheme))

        #expect(markup.extra < 0)
    }

    @Test(arguments: [(Cadence.monthly, 12), (.annual, 1), (.weekly, 52), (.quarterly, 4)])
    func annualisingMultipliesByAyearOfCharges(_ cadence: Cadence, _ times: Int) throws {
        let markup = try #require(paidFromBalance().markup(against: decimal("2.5939"), reference: .cardScheme))

        #expect(markup.annualised(at: cadence) == markup.extra * Decimal(times))
    }

    @Test(arguments: ["0", "-1"])
    func anonsenseReferenceRateIsRefusedRatherThanDividedBy(_ rate: String) {
        #expect(paidFromBalance().markup(against: decimal(rate), reference: .cardScheme) == nil)
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
        let markup = try #require(subscription([paidFromBalance()]).markup(against: official, calendar: utc))

        #expect(markup.reference == .cardScheme)
    }

    @Test func theofficialRateIsTheFallback() throws {
        let charge = paidFromBalance(scheme: nil)
        let markup = try #require(subscription([charge]).markup(against: official, calendar: utc))

        #expect(markup.reference == .official)
    }

    @Test func withNeitherRateThereIsNoMarkup() {
        let charge = paidFromBalance(scheme: nil)

        #expect(subscription([charge]).markup(against: [], calendar: utc) == nil)
    }

    @Test func itusesTheNewestConvertedCharge() throws {
        let subject = subscription([
            paidFromBalance("2026-06-20", bank: "2.6505", scheme: "2.6150"),
            paidFromBalance("2026-07-20"),
        ])

        #expect(try #require(subject.markup(calendar: utc)).paid == decimal("15.20"))
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
