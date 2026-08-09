import Foundation
import Testing

@testable import Core

private func subscription(
    _ merchant: String, _ amount: String, _ currency: String, _ cadence: Cadence,
    active: Bool = true
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency, cadence: cadence,
        firstChargeDate: .distantPast, lastChargeDate: .distantPast, nextChargeDate: .distantPast,
        occurrenceCount: 3, isActive: active, confidence: .confident)
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
        rates.record(CurrencyConversion(from: "USD", to: "GEL", bankRate: Decimal(string: "2.6716")!))

        let result = [
            subscription("SETANTA", "14.99", "GEL", .monthly),
            subscription("Adobe", "19.99", "USD", .monthly),
        ].monthlyTotal(in: "GEL", rates: rates)

        #expect(result.unconvertible.isEmpty)
        #expect(result.total == Decimal(string: "14.99")! + Decimal(string: "19.99")! * Decimal(string: "2.6716")!)
    }

    /// A currency the statement never converted must be reported, never silently dropped.
    @Test func reportsWhatItCannotConvert() {
        var rates = RateBook()
        rates.record(CurrencyConversion(from: "USD", to: "GEL", bankRate: 2))

        let result = [
            subscription("SETANTA", "10.00", "GEL", .monthly),
            subscription("Epidemic", "8.99", "EUR", .monthly),
        ].monthlyTotal(in: "GEL", rates: rates)

        #expect(result.total == 10)
        #expect(result.unconvertible.map(\.merchant) == ["Epidemic"])
    }

    @Test func cancelledSubscriptionsDoNotCount() {
        let result = [subscription("X", "10.00", "GEL", .monthly, active: false)]
            .monthlyTotal(in: "GEL", rates: RateBook())
        #expect(result.total == 0)
    }

    @Test func invertsARateWhenOnlyTheOppositeDirectionIsKnown() {
        var rates = RateBook()
        rates.record(CurrencyConversion(from: "USD", to: "GEL", bankRate: 2))
        #expect(rates.rate(from: "GEL", to: "USD") == Decimal(1) / 2)
        #expect(rates.rate(from: "GEL", to: "GEL") == 1)
    }

    @Test func markupIsTheGapBetweenBankAndSchemeRates() {
        let conversion = CurrencyConversion(
            from: "USD", to: "GEL", bankRate: Decimal(string: "2.6716")!,
            schemeRate: Decimal(string: "2.6317")!)
        let markup = try! #require(conversion.markupFraction)
        #expect(markup > Decimal(string: "0.014")! && markup < Decimal(string: "0.016")!)
    }
}
