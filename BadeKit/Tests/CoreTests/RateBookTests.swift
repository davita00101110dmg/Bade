import Foundation
import Testing

@testable import Core

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

@Suite("Rate book")
struct RateBookTests {
    private func book(_ rates: [(String, String, String, Decimal)]) -> RateBook {
        var book = RateBook()
        for (date, from, to, rate) in rates {
            book.record(ObservedRate(date: day(date), from: from, to: to, rate: rate))
        }
        return book
    }

    @Test func picksTheRateNearestTheCharge() {
        let rates = book([
            ("2025-01-10", "USD", "GEL", 2.59),
            ("2026-01-10", "USD", "GEL", 2.76),
        ])

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2025-02-01")) == 2.59)
        #expect(rates.rate(from: "USD", to: "GEL", on: day("2025-12-01")) == 2.76)
    }

    /// Eighteen months of lari drift is several percent; one rate for a whole statement is wrong
    /// at both ends of it.
    @Test func nearestBeatsMostRecentlyRecorded() {
        let rates = book([
            ("2026-01-10", "USD", "GEL", 2.76),
            ("2025-01-10", "USD", "GEL", 2.59),
        ])

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2025-01-11")) == 2.59)
    }

    @Test func readsAPairBackwards() {
        let rates = book([("2026-01-10", "GEL", "EUR", 0.32)])

        let rate = rates.rate(from: "EUR", to: "GEL", on: day("2026-01-10"))
        #expect(rate == Decimal(1) / Decimal(string: "0.32")!)
    }

    @Test func aCurrencyIsWorthItself() {
        #expect(RateBook().rate(from: "GEL", to: "GEL", on: day("2026-01-10")) == 1)
    }

    /// Nothing extrapolates: a pair never seen stays unconvertible rather than being guessed at.
    @Test func anUnseenPairHasNoRate() {
        let rates = book([("2026-01-10", "USD", "GEL", 2.7)])

        #expect(rates.rate(from: "EUR", to: "GEL", on: day("2026-01-10")) == nil)
        #expect(rates.convert(10, from: "EUR", to: "GEL", on: day("2026-01-10")) == nil)
    }

    @Test func rejectsRatesThatCannotBeInverted() {
        var rates = RateBook()
        rates.record(ObservedRate(date: day("2026-01-10"), from: "USD", to: "GEL", rate: 0))

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2026-01-10")) == nil)
    }

    @Test func convertsAtTheNearestRate() {
        let rates = book([
            ("2025-01-10", "USD", "GEL", 2.5),
            ("2026-01-10", "USD", "GEL", 3),
        ])

        #expect(rates.convert(10, from: "USD", to: "GEL", on: day("2026-01-09")) == 30)
    }
}
