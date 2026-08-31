import Foundation
import Testing

@testable import Core

/// These subscriptions are dated `.distantPast`, so any observation is the nearest one.
private let anyDay = Date.distantPast

private func subscription(
    _ merchant: String, _ amount: String, _ currency: String, _ cadence: Cadence,
    active: Bool = true
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency, cadence: cadence,
        firstChargeDate: .distantPast, lastChargeDate: .distantPast, nextChargeDate: .distantPast,
        isActive: active, confidence: .confident)
}

@Suite("Monthly normalisation")
struct MonthlyTotalTests {
    @Test(arguments: [
        (Cadence.monthly, "12.00"), (.annual, "1.00"), (.quarterly, "4.00"), (.semiannual, "2.00"),
    ])
    func normalisesEachCadenceOntoOneFigure(cadence: Cadence, monthly: String) {
        let yearly = subscription("X", "12.00", "GEL", cadence)
        #expect(yearly.monthlyAmount == Decimal(string: monthly)!)
    }

    @Test func weeklyUsesFiftyTwoWeeksNotFourWeeks() {
        #expect(subscription("X", "12.00", "GEL", .weekly).monthlyAmount == 52)
    }

    /// Dividing by 12 cannot round-trip in any decimal system — 1/12 repeats forever. What §14.3
    /// requires is that the error stays far below any currency's smallest unit.
    @Test(arguments: ["0.01", "9.99", "139.00", "1234.5678"])
    func normalisationDriftIsNegligible(amount: String) {
        let value = Decimal(string: amount)!
        for (cadence, periods) in [(Cadence.annual, Decimal(12)), (.quarterly, 3), (.semiannual, 6)] {
            let drift = abs(cadence.monthlyEquivalent(of: value) * periods - value)
            #expect(drift < Decimal(string: "0.000000000000001")!, "\(cadence) drifted by \(drift)")
        }
    }

    /// Amounts that divide evenly must be exact, with no trailing-digit noise.
    @Test func evenDivisionsAreExact() {
        #expect(Cadence.annual.monthlyEquivalent(of: 120) == 10)
        #expect(Cadence.quarterly.monthlyEquivalent(of: Decimal(string: "36.00")!) == 12)
        #expect(Cadence.semiannual.monthlyEquivalent(of: 60) == 10)
    }

    @Test func sumsAcrossCurrenciesUsingObservedRates() {
        var rates = RateBook()
        rates.record(
            ObservedRate(
                date: anyDay, from: "USD", to: "GEL",
                rate: Decimal(string: "2.6716")!))

        let result = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly),
        ].monthlyTotal(in: "GEL", rates: rates, on: anyDay)

        #expect(result.unconvertible.isEmpty)
        #expect(result.total == Decimal(string: "14.99")! + Decimal(string: "19.99")! * Decimal(string: "2.6716")!)
    }

    /// What an import has just detected has to be able to answer this too. On a first import
    /// nothing is stored yet, so a statement priced in lari was being totalled in the phone's
    /// locale currency on the one screen where the whole import is decided.
    @Test func detectionsAnswerWhatToTotalInBeforeAnythingIsStored() {
        let detected = [
            DetectedSubscription(
                merchant: "MAGTICOM", amount: 35, currency: "GEL", cadence: .monthly,
                occurrences: [], nextChargeDate: .distantPast, confidence: .confident,
                priceChanges: []),
            DetectedSubscription(
                merchant: "Spotify", amount: 15, currency: "GEL", cadence: .monthly,
                occurrences: [], nextChargeDate: .distantPast, confidence: .confident,
                priceChanges: []),
            DetectedSubscription(
                merchant: "ChatGPT", amount: 20, currency: "USD", cadence: .monthly,
                occurrences: [], nextChargeDate: .distantPast, confidence: .confident,
                priceChanges: []),
        ]

        #expect(detected.predominantCurrency == "GEL")
        #expect([DetectedSubscription]().predominantCurrency == nil)
    }

    /// One date for the whole sum, not each subscription's own history. Rates are chosen by nearest
    /// observation, so converting line by line at each last charge made this total and the
    /// calendar's disagree by a few tetri — with nothing on either screen to explain the gap.
    @Test func everyLineIsConvertedAtOneDate() {
        let january = Date(timeIntervalSince1970: 1_767_225_600)
        let august = Date(timeIntervalSince1970: 1_785_542_400)
        var rates = RateBook()
        rates.record(ObservedRate(date: january, from: "USD", to: "GEL", rate: 2))
        rates.record(ObservedRate(date: august, from: "USD", to: "GEL", rate: 3))

        let charges = [
            subscription("Old", "10.00", "USD", .monthly),
            subscription("New", "10.00", "USD", .monthly),
        ]

        #expect(charges.monthlyTotal(in: "GEL", rates: rates, on: january).total == 40)
        #expect(charges.monthlyTotal(in: "GEL", rates: rates, on: august).total == 60)
    }

    /// A currency the statement never converted must be reported, never silently dropped.
    @Test func reportsWhatItCannotConvert() {
        var rates = RateBook()
        rates.record(ObservedRate(date: anyDay, from: "USD", to: "GEL", rate: 2))

        let result = [
            subscription("SETANTA", "10.00", "GEL", .monthly),
            subscription("Epidemic", "8.99", "EUR", .monthly),
        ].monthlyTotal(in: "GEL", rates: rates, on: anyDay)

        #expect(result.total == 10)
        #expect(result.unconvertible.map(\.merchant) == ["Epidemic"])
    }

    @Test func cancelledSubscriptionsDoNotCount() {
        let result = [subscription("X", "10.00", "GEL", .monthly, active: false)]
            .monthlyTotal(in: "GEL", rates: RateBook(), on: anyDay)
        #expect(result.total == 0)
    }

    @Test func invertsARateWhenOnlyTheOppositeDirectionIsKnown() {
        var rates = RateBook()
        rates.record(ObservedRate(date: anyDay, from: "USD", to: "GEL", rate: 2))
        #expect(rates.rate(from: "GEL", to: "USD", on: anyDay) == Decimal(1) / 2)
        #expect(rates.rate(from: "GEL", to: "GEL", on: anyDay) == 1)
    }

    @Test func markupIsTheGapBetweenBankAndSchemeRates() {
        let conversion = CurrencyConversion(
            from: "USD", to: "GEL", bankRate: Decimal(string: "2.6716")!,
            schemeRate: Decimal(string: "2.6317")!)
        let markup = try! #require(conversion.markupFraction)
        #expect(markup > Decimal(string: "0.014")! && markup < Decimal(string: "0.016")!)
    }
}

/// The display currency is only honest where every active subscription reaches it.
@Suite("Convertible currencies")
struct ConvertibleCurrencyTests {
    private func rates(_ pairs: [(String, String, String)]) -> RateBook {
        var book = RateBook()
        for (from, to, rate) in pairs {
            book.record(
                ObservedRate(date: anyDay, from: from, to: to, rate: Decimal(string: rate)!))
        }
        return book
    }

    /// One currency in, one currency out. Nothing to convert, so nothing can fail.
    @Test func aSingleCurrencyOffersOnlyItself() {
        let only = [subscription("SETANTA", "14.99", "GEL", .monthly)]

        #expect(only.convertibleCurrencies(rates: RateBook(), on: anyDay) == ["GEL"])
    }

    /// An observed pair works in both directions, because a rate book inverts what it holds.
    @Test func anObservedPairOffersBothOfItsSides() {
        let mixed = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly),
        ]

        let offered = mixed.convertibleCurrencies(
            rates: rates([("USD", "GEL", "2.6716")]), on: anyDay)

        #expect(offered == ["GEL", "USD"])
    }

    /// The bug this was written for: holding GEL-USD says nothing about GEL-JPY, because a rate
    /// book never triangulates. JPY was offered anyway and totalled to zero.
    @Test func aCurrencyNothingReachesIsNotOffered() {
        let mixed = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly),
        ]

        let offered = mixed.convertibleCurrencies(
            rates: rates([("USD", "GEL", "2.6716")]), on: anyDay)

        #expect(!offered.contains("JPY"))
    }

    /// A currency you are plainly charged in, that your other subscriptions still cannot reach.
    /// A multi-currency account pays a dollar charge from a dollar balance and records no rate
    /// doing it — so "the currencies you have" is the wrong question to ask.
    @Test func aCurrencyChargedInWithNoRateToItIsNotOffered() {
        let mixed = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly),
        ]

        #expect(mixed.convertibleCurrencies(rates: RateBook(), on: anyDay).isEmpty)
    }

    /// Cancelled subscriptions are not in the total, so they cannot narrow what it shows in.
    @Test func aCancelledSubscriptionDoesNotRestrictTheChoice() {
        let mixed = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly, active: false),
        ]

        #expect(mixed.convertibleCurrencies(rates: RateBook(), on: anyDay) == ["GEL"])
    }

    /// Three currencies, and a rate reaching only two of them: neither of the pair is offered,
    /// because the third would be left unconverted in both.
    @Test func onePairIsNotEnoughWhenAThirdCurrencyIsStranded() {
        let mixed = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly),
            subscription("Bolt", "9.99", "EUR", .monthly),
        ]

        let offered = mixed.convertibleCurrencies(
            rates: rates([("USD", "GEL", "2.6716")]), on: anyDay)

        #expect(offered.isEmpty)
    }
}

/// The shape of a real account: lari, dollars and euros, each paid from the balance already in
/// that currency. Nothing was ever converted, so the statement records not one rate — and until
/// the publisher's reached the totals, two of the three were missing from the headline figure and
/// Settings had no currency left to offer.
@Suite("An account that converted nothing")
struct UnconvertedAccountTests {
    private let subscriptions = [
        subscription("SETANTA", "14.99", "GEL", .monthly),
        subscription("Adobe", "19.99", "USD", .monthly),
        subscription("Bolt", "9.99", "EUR", .monthly),
    ]

    private var published: RateBook {
        var book = RateBook()
        book.record(
            [
                OfficialRate(date: anyDay, currency: "USD", rate: Decimal(string: "2.70")!),
                OfficialRate(date: anyDay, currency: "EUR", rate: Decimal(string: "2.95")!),
            ], base: "GEL")
        return book
    }

    @Test func theHeadlineFigureLeavesNothingOut() {
        let total = subscriptions.monthlyTotal(in: "GEL", rates: published, on: anyDay)

        #expect(total.unconvertible.isEmpty)
        #expect(
            total.total
                == Decimal(string: "14.99")! + Decimal(string: "19.99")! * Decimal(string: "2.70")!
                    + Decimal(string: "9.99")! * Decimal(string: "2.95")!)
    }

    /// Every currency the statement charged in, which is the choice Settings offers.
    @Test func eachCurrencyChargedCanBeTotalledIn() {
        #expect(
            subscriptions.convertibleCurrencies(rates: published, on: anyDay)
                == ["EUR", "GEL", "USD"])
    }

    /// The bug as reported. Two subscriptions absent from the total, and not one currency the
    /// total could honestly be shown in — which is what made Settings drop the row entirely.
    @Test func observedRatesAloneLeaveItShortAndWithNoChoice() {
        let total = subscriptions.monthlyTotal(in: "GEL", rates: RateBook(), on: anyDay)

        #expect(total.unconvertible.count == 2)
        #expect(subscriptions.convertibleCurrencies(rates: RateBook(), on: anyDay).isEmpty)
    }
}
