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

/// An account that pays each currency from its own balance converts nothing and so observes no
/// rates at all. What the publisher priced is the only thing that can total it.
@Suite("Published rates")
struct PublishedRateTests {
    private func book(
        observed: [(String, String, String, Decimal)] = [],
        published: [(String, String, Decimal)],
        base: String = "GEL"
    ) -> RateBook {
        var book = RateBook()
        for (date, from, to, rate) in observed {
            book.record(ObservedRate(date: day(date), from: from, to: to, rate: rate))
        }
        book.record(
            published.map { OfficialRate(date: day($0.0), currency: $0.1, rate: $0.2) }, base: base)
        return book
    }

    /// Neither leg was ever converted by a bank, and the publisher lists no such pair — but it
    /// prices both against the base, and that is a rate rather than a guess.
    @Test func bridgesAPairNoStatementEverConverted() {
        let rates = book(published: [
            ("2026-01-10", "USD", Decimal(string: "2.70")!),
            ("2026-01-10", "EUR", Decimal(string: "2.95")!),
        ])

        let rate = rates.rate(from: "USD", to: "EUR", on: day("2026-01-10"))
        #expect(rate == Decimal(string: "2.70")! / Decimal(string: "2.95")!)
    }

    @Test func pricesTheBaseInBothDirections() {
        let rates = book(published: [("2026-01-10", "USD", Decimal(string: "2.70")!)])

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2026-01-10")) == Decimal(string: "2.70")!)
        #expect(
            rates.rate(from: "GEL", to: "USD", on: day("2026-01-10"))
                == 1 / Decimal(string: "2.70")!)
    }

    /// What the bank charged is what happened to this money. The published rate only fills gaps,
    /// and must never quietly restate a conversion the statement already recorded.
    @Test func whatTheBankChargedWins() {
        let rates = book(
            observed: [("2026-01-10", "USD", "GEL", Decimal(string: "2.80")!)],
            published: [("2026-01-10", "USD", Decimal(string: "2.70")!)])

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2026-01-10")) == Decimal(string: "2.80")!)
    }

    /// A central bank does not publish at the weekend; a total read on Sunday takes Friday's.
    @Test func fallsBackToTheNearestPublicationDay() {
        let rates = book(published: [
            ("2026-01-09", "USD", Decimal(string: "2.70")!),
            ("2026-01-05", "USD", Decimal(string: "2.60")!),
        ])

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2026-01-11")) == Decimal(string: "2.70")!)
    }

    @Test func aCurrencyThePublisherDoesNotListStaysUnconvertible() {
        let rates = book(published: [("2026-01-10", "USD", Decimal(string: "2.70")!)])

        #expect(rates.rate(from: "JPY", to: "GEL", on: day("2026-01-10")) == nil)
    }

    /// The whole of what turning the network off costs: exactly the behaviour there was before.
    @Test func nothingPublishedChangesNothing() {
        var rates = RateBook()
        rates.record([], base: "GEL")

        #expect(rates.rate(from: "USD", to: "GEL", on: day("2026-01-10")) == nil)
    }

    /// The widget's snapshot is JSON on disk, written by a build that had no published rates in it.
    @Test func aBookWrittenBeforePublishedRatesStillDecodes() throws {
        let old = Data(#"{"observed":{}}"#.utf8)

        let book = try JSONDecoder().decode(RateBook.self, from: old)
        #expect(book == RateBook())
    }
}
