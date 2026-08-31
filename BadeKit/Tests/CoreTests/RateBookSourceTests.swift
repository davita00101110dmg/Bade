import Foundation
import Testing

@testable import Core

private actor Asked {
    private(set) var currencies: Set<String> = []
    private(set) var dates: Set<Date> = []
    private(set) var calls = 0

    func record(_ currencies: Set<String>, _ dates: Set<Date>) {
        self.currencies = currencies
        self.dates = dates
        calls += 1
    }
}

private struct SpyPublisher: OfficialRateSource {
    let asked: Asked
    var answers: [OfficialRate] = []

    func rates(for currencies: Set<String>, on dates: Set<Date>) async -> [OfficialRate] {
        await asked.record(currencies, dates)
        return answers
    }
}

private struct StubRates: RateRepository {
    var book = RateBook()

    func observedRates() async throws -> RateBook { book }
    func record(_ rates: RateBook) async throws {}
}

private struct StubSubscriptions: SubscriptionRepository {
    let stored: [Subscription]

    func all() async throws -> [Subscription] { stored }
    func save(_ subscription: Subscription) async throws {}
    func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
    func delete(id: UUID) async throws {}
    func deleteAll() async throws {}
}

private func subscription(_ currency: String) -> Subscription {
    Subscription(
        merchant: currency, amount: 10, currency: currency, cadence: .monthly,
        firstChargeDate: .distantPast, lastChargeDate: .distantPast, nextChargeDate: .distantPast,
        confidence: .confident)
}

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let today = Date(timeIntervalSince1970: 1_767_052_800)  // 2025-12-30, a Tuesday.

@Suite("Rate book source")
struct RateBookSourceTests {
    private func source(
        observed: RateBook = RateBook(), stored: [Subscription], publisher: SpyPublisher
    ) -> RateBookSource {
        RateBookSource(
            rates: StubRates(book: observed), subscriptions: StubSubscriptions(stored: stored),
            published: publisher, base: "GEL", calendar: utc)
    }

    /// Asking for the base marks every day incomplete — a publisher never lists its own currency —
    /// and the cache would then re-fetch the same days on every single launch.
    @Test func neverAsksThePublisherToPriceItsOwnCurrency() async {
        let asked = Asked()
        let source = source(
            stored: [subscription("GEL"), subscription("USD"), subscription("EUR")],
            publisher: SpyPublisher(asked: asked))

        _ = await source.book(totalling: "GEL", on: today)

        #expect(await asked.currencies == ["USD", "EUR"])
    }

    /// A market closed for a weekend and a Monday holiday puts the last publication three days back.
    @Test func asksForEnoughDaysToSurviveAClosedMarket() async {
        let asked = Asked()
        let source = source(stored: [subscription("USD")], publisher: SpyPublisher(asked: asked))

        _ = await source.book(totalling: "GEL", on: today)

        let days = await asked.dates
        #expect(days.count == 4)
        #expect(days.contains(utc.startOfDay(for: today)))
        #expect(days.contains(utc.date(byAdding: .day, value: -3, to: utc.startOfDay(for: today))!))
    }

    @Test func fillsThePairsNoStatementConverted() async {
        let asked = Asked()
        let publisher = SpyPublisher(
            asked: asked,
            answers: [
                OfficialRate(
                    date: utc.startOfDay(for: today), currency: "USD",
                    rate: Decimal(string: "2.70")!)
            ])
        let source = source(stored: [subscription("USD")], publisher: publisher)

        let book = await source.book(totalling: "GEL", on: today)

        #expect(book.convert(10, from: "USD", to: "GEL", on: today) == 27)
    }

    @Test func keepsWhatTheStatementAlreadyObserved() async {
        var observed = RateBook()
        observed.record(
            ObservedRate(date: today, from: "USD", to: "GEL", rate: Decimal(string: "2.80")!))
        let source = source(
            observed: observed, stored: [subscription("USD")],
            publisher: SpyPublisher(asked: Asked()))

        let book = await source.book(totalling: "GEL", on: today)

        #expect(book.convert(10, from: "USD", to: "GEL", on: today) == 28)
    }

    /// Nothing to bridge, so nothing is asked — the network stays unused on the common case of an
    /// account billed entirely in one currency.
    @Test func asksForNothingWhenEverythingIsAlreadyInTheBase() async {
        let asked = Asked()
        let source = source(stored: [subscription("GEL")], publisher: SpyPublisher(asked: asked))

        _ = await source.book(totalling: "GEL", on: today)

        #expect(await asked.calls == 0)
    }

    /// The currency being totalled in need not be one anything is charged in — a lari statement
    /// read in dollars still needs the pair.
    @Test func includesTheCurrencyBeingTotalledIn() async {
        let asked = Asked()
        let source = source(stored: [subscription("GEL")], publisher: SpyPublisher(asked: asked))

        _ = await source.book(totalling: "USD", on: today)

        #expect(await asked.currencies == ["USD"])
    }
}
