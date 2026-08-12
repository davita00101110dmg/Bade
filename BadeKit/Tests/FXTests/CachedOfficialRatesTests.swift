import Core
import Foundation
import Testing

@testable import FX

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private func rate(_ iso: String, _ currency: String = "USD", _ value: Decimal = 2.61)
    -> OfficialRate
{
    OfficialRate(date: day(iso), currency: currency, rate: value)
}

private final class Store: OfficialRateStore, @unchecked Sendable {
    private(set) var held: [OfficialRate]
    private(set) var recorded: [OfficialRate] = []

    init(_ held: [OfficialRate] = []) { self.held = held }

    func officialRates(for currencies: Set<String>, on dates: Set<Date>) async throws
        -> [OfficialRate]
    {
        held.filter { currencies.contains($0.currency) && dates.contains($0.date) }
    }

    func record(_ rates: [OfficialRate]) async throws {
        recorded += rates
        held += rates
    }
}

private final class Network: OfficialRateSource, @unchecked Sendable {
    private let answers: [OfficialRate]
    private(set) var askedFor: Set<Date> = []

    init(_ answers: [OfficialRate] = []) { self.answers = answers }

    func rates(for currencies: Set<String>, on dates: Set<Date>) async -> [OfficialRate] {
        askedFor.formUnion(dates)
        return answers.filter { dates.contains($0.date) && currencies.contains($0.currency) }
    }
}

@Suite("Caching official rates")
struct CachedOfficialRatesTests {
    @Test func aknownDayIsNeverAskedForAgain() async {
        let network = Network()
        let subject = CachedOfficialRates(store: Store([rate("2026-08-07")]), network: network)

        let rates = await subject.rates(for: ["USD"], on: [day("2026-08-07")])

        #expect(rates.count == 1)
        #expect(network.askedFor.isEmpty, "the day was already known")
    }

    @Test func anunknownDayIsFetchedAndKept() async {
        let store = Store()
        let subject = CachedOfficialRates(
            store: store, network: Network([rate("2026-08-07")]))

        let rates = await subject.rates(for: ["USD"], on: [day("2026-08-07")])

        #expect(rates.count == 1)
        #expect(store.recorded.count == 1, "kept, so tomorrow costs nothing")
    }

    @Test func onlyTheMissingDaysAreFetched() async {
        let network = Network([rate("2026-08-08")])
        let subject = CachedOfficialRates(store: Store([rate("2026-08-07")]), network: network)

        _ = await subject.rates(for: ["USD"], on: [day("2026-08-07"), day("2026-08-08")])

        #expect(network.askedFor == [day("2026-08-08")])
    }

    /// A day known for one currency but not another is not known: the second subscription's
    /// markup would silently go missing.
    @Test func adayHalfKnownIsFetchedAgain() async {
        let network = Network([rate("2026-08-07", "EUR", 2.95)])
        let subject = CachedOfficialRates(store: Store([rate("2026-08-07")]), network: network)

        let rates = await subject.rates(for: ["USD", "EUR"], on: [day("2026-08-07")])

        #expect(network.askedFor == [day("2026-08-07")])
        #expect(Set(rates.map(\.currency)) == ["USD", "EUR"])
    }

    /// Switched off, the cache still answers for everything already fetched.
    @Test func withTheNetworkOffWhatIsKnownStillWorks() async {
        let subject = CachedOfficialRates(store: Store([rate("2026-08-07")]), network: nil)

        #expect(await subject.rates(for: ["USD"], on: [day("2026-08-07")]).count == 1)
        #expect(await subject.rates(for: ["USD"], on: [day("2026-08-08")]).isEmpty)
    }

    @Test func afailedFetchLeavesTheCacheAloneRatherThanBreaking() async {
        let store = Store()
        let subject = CachedOfficialRates(store: store, network: Network())

        #expect(await subject.rates(for: ["USD"], on: [day("2026-08-07")]).isEmpty)
        #expect(store.recorded.isEmpty)
    }
}
