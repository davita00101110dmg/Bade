/// Rates gathered from every statement imported so far. Separate from subscriptions because they
/// answer a different question and outlive any one import: a charge imported today may be best
/// converted by a rate a statement imported next month happens to carry.
public protocol RateRepository: Sendable {
    func observedRates() async throws -> RateBook
    func record(_ rates: RateBook) async throws
}
