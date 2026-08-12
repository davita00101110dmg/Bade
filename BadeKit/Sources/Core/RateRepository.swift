import Foundation

/// Rates gathered from every statement imported so far. Separate from subscriptions because they
/// answer a different question and outlive any one import: a charge imported today may be best
/// converted by a rate a statement imported next month happens to carry.
public protocol RateRepository: Sendable {
    func observedRates() async throws -> RateBook
    func record(_ rates: RateBook) async throws
}

/// Official rates already fetched. Cached because they never change once published — a day's rate
/// is a fact — so the network is asked for any given day exactly once, ever.
public protocol OfficialRateStore: Sendable {
    func officialRates(for currencies: Set<String>, on dates: Set<Date>) async throws
        -> [OfficialRate]
    func record(_ rates: [OfficialRate]) async throws
}
