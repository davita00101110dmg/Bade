import Core
import Foundation
import Testing

@testable import Ingestion

private let parser = BOGStatementParser()

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

/// Money is compared exactly; a rate derived by division is a repeating decimal and is not.
private func isClose(_ value: Decimal?, _ expected: String) -> Bool {
    guard let value else { return false }
    return abs(value - Decimal(string: expected)!) < Decimal(string: "0.00001")!
}

/// The account holder's own conversions. They carry no merchant, so they are not transactions —
/// but they are the only place a EUR or GBP rate appears when those charges settle from a balance
/// held in that currency.
@Suite("BOG exchange rates")
struct BOGExchangeRateTests {
    @Test func readsBothSidesOfAConversion() throws {
        let statement = """
            16/06/2025 Payment - Amount GEL270.00; Foreign Exchange. FX Rate:2.7. \
            Counter-amount: USD100.00. konvertatsia
            """

        let rates = parser.exchangeRates(in: statement)
        #expect(rates.count == 1)
        #expect(rates[0].from == "GEL")
        #expect(rates[0].to == "USD")
        #expect(isClose(rates[0].rate, "0.370370"))
        #expect(rates[0].date == day("2025-06-16"))
    }

    /// The printed `FX Rate` is quoted lari-per-foreign whichever way the conversion went, so the
    /// rate is derived from the two amounts instead of trusted from the label.
    @Test func derivesTheRateFromTheAmountsNotThePrintedLabel() throws {
        let statement = """
            17/06/2025 Payment - Amount USD100.00; Foreign Exchange. FX Rate:2.7. \
            Counter-amount: GEL270.00. konvertatsia
            """

        let rates = parser.exchangeRates(in: statement)
        #expect(rates.count == 1)
        #expect(rates[0].from == "USD")
        #expect(rates[0].to == "GEL")
        #expect(rates[0].rate == Decimal(string: "2.7")!)
    }

    @Test func aEuroConversionIsTheOnlyPlaceAEuroRateAppears() throws {
        let statement = """
            10/03/2026 Payment - Amount GEL295.00; Foreign Exchange. FX Rate:2.95. \
            Counter-amount: EUR100.00. konvertatsia
            """

        var book = RateBook()
        for rate in parser.exchangeRates(in: statement) { book.record(rate) }

        #expect(isClose(book.rate(from: "EUR", to: "GEL", on: day("2026-03-10")), "2.95"))
    }

    @Test func survivesThousandsSeparatorsAndATruncatedCounterAmount() throws {
        let statement = """
            16/06/2025 Payment - Amount GEL15,518.09; Foreign Exchange. FX Rate:2.757. \
            Counter-amount: USD5,628.61. konvertatsia 18/06/2025 Income - Amount GEL178.76; \
            Foreign Exchange. FX Rate:2.668. Counter-amount: USD67.. konvertatsia
            """

        let rates = parser.exchangeRates(in: statement)
        #expect(rates.count == 2)
        #expect(rates[1].date == day("2025-06-18"))
        #expect(rates[1].to == "USD")
    }

    @Test func takesTheDateFromTheColumnAheadOfTheRow() throws {
        let statement = """
            01/02/2026 Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, \
            United States of America; MCC:4899; Date: 01/02/2026 00:00; Card No: ****0000; \
            05/03/2026 Payment - Amount GEL270.00; Foreign Exchange. FX Rate:2.7. \
            Counter-amount: USD100.00. konvertatsia
            """

        let rates = parser.exchangeRates(in: statement)
        #expect(rates.count == 1)
        #expect(rates[0].date == day("2026-03-05"))
    }

    @Test func aStatementWithNoConversionsYieldsNone() {
        let statement = """
            09/05/2026 Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, \
            United States of America; MCC:4899; Date: 27/05/2026 00:00; Card No: ****0000;
            """

        #expect(parser.exchangeRates(in: statement).isEmpty)
    }

    /// A conversion is not a purchase; it must not become a subscription.
    @Test func conversionRowsAreNotTransactions() throws {
        let statement = """
            09/05/2026 Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, \
            United States of America; MCC:4899; Date: 27/05/2026 00:00; Card No: ****0000; \
            16/06/2025 Payment - Amount GEL270.00; Foreign Exchange. FX Rate:2.7. \
            Counter-amount: USD100.00. konvertatsia
            """

        #expect(try parser.parse(statement).count == 1)
    }
}
