import Core
import Foundation
import Testing

@testable import Persistence

private func stamp(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

private func newStore() throws -> SubscriptionStore {
    try TestContainers.store()
}

private func book(_ rates: [(String, String, String, Decimal)]) -> RateBook {
    var book = RateBook()
    for (date, from, to, rate) in rates {
        book.record(ObservedRate(date: stamp(date), from: from, to: to, rate: rate))
    }
    return book
}

/// SwiftData containers are not safe to spin up concurrently; parallel execution segfaults.
@Suite("Rate store", .serialized)
struct RateStoreTests {
    @Test func startsEmpty() async throws {
        let store = try newStore()
        let rates = try await store.observedRates()

        #expect(rates.rate(from: "USD", to: "GEL", on: stamp("2026-01-01")) == nil)
    }

    @Test func ratesSurviveToBeReadBack() async throws {
        let store = try newStore()
        try await store.record(book([("2026-01-10", "USD", "GEL", 2.7)]))

        let rates = try await store.observedRates()
        #expect(rates.rate(from: "USD", to: "GEL", on: stamp("2026-01-10")) == Decimal(string: "2.7")!)
    }

    /// A later statement can carry the rate that finally converts a charge imported today.
    @Test func ratesAccumulateAcrossImports() async throws {
        let store = try newStore()
        try await store.record(book([("2026-01-10", "USD", "GEL", 2.7)]))
        try await store.record(book([("2026-01-10", "EUR", "GEL", 2.95)]))

        let rates = try await store.observedRates()
        #expect(rates.rate(from: "USD", to: "GEL", on: stamp("2026-01-10")) != nil)
        #expect(rates.rate(from: "EUR", to: "GEL", on: stamp("2026-01-10")) != nil)
    }

    @Test func reimportingTheSameStatementDoesNotStackDuplicates() async throws {
        let store = try newStore()
        let observed = book([
            ("2026-01-10", "USD", "GEL", 2.7),
            ("2026-02-10", "USD", "GEL", 2.8),
        ])
        try await store.record(observed)
        try await store.record(observed)

        #expect(try await store.observedRates().observations.count == 2)
    }

    /// Two observations of the same pair on the same day at different rates are both real.
    @Test func keepsTwoRatesFromTheSameDay() async throws {
        let store = try newStore()
        try await store.record(
            book([("2026-01-10", "USD", "GEL", 2.7), ("2026-01-10", "USD", "GEL", 2.72)]))

        #expect(try await store.observedRates().observations.count == 2)
    }

    @Test func deletingEverythingLeavesNoRatesBehind() async throws {
        let store = try newStore()
        try await store.record(book([("2026-01-10", "USD", "GEL", 2.7)]))

        try await store.deleteAll()

        #expect(try await store.observedRates().observations.isEmpty)
    }
}
