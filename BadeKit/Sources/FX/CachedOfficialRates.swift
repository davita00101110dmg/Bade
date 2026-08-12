import Core
import Foundation

/// The network behind a cache. A published rate is a fact about a day that has already happened,
/// so once a day is known it is never asked for again — which is what keeps the one network call
/// in the app rare, and what makes the FX section instant on the second look.
///
/// Switched off, this becomes the cache alone: everything already fetched still works, and nothing
/// new is asked for. That is the whole of what turning the network off costs.
public struct CachedOfficialRates: OfficialRateSource {
    private let store: any OfficialRateStore
    private let network: (any OfficialRateSource)?

    /// `network` is `nil` when the user has turned the fetch off.
    public init(store: any OfficialRateStore, network: (any OfficialRateSource)?) {
        self.store = store
        self.network = network
    }

    public func rates(for currencies: Set<String>, on dates: Set<Date>) async -> [OfficialRate] {
        let cached = (try? await store.officialRates(for: currencies, on: dates)) ?? []
        guard let network else { return cached }

        let missing = dates.subtracting(covered(by: cached, wanting: currencies, across: dates))
        guard !missing.isEmpty else { return cached }

        let fetched = await network.rates(for: currencies, on: missing)
        guard !fetched.isEmpty else { return cached }
        try? await store.record(fetched)
        return cached + fetched
    }

    /// A day counts as known only when every currency asked about has a rate on it; otherwise the
    /// day is fetched again, since a partial answer would silently hide one subscription's markup.
    private func covered(
        by rates: [OfficialRate], wanting currencies: Set<String>, across dates: Set<Date>
    ) -> Set<Date> {
        dates.filter { date in
            let known = Set(
                rates.filter { $0.date.timeIntervalSince1970 == date.timeIntervalSince1970 }
                    .map(\.currency))
            return currencies.isSubset(of: known)
        }
    }
}
