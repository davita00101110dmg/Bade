import Core
import Foundation

/// Splits one merchant's charges into subscription candidates.
struct ChargeGrouper {
    private let cadenceResolver = CadenceResolver()

    func clusters(for charges: [NormalizedTransaction]) -> [ChargeCluster] {
        let ordered = charges.sorted { $0.raw.date < $1.raw.date }
        if let rhythm = oneRhythm(ordered) { return [rhythm] }
        return amountClusters(of: ordered)
    }

    /// One rhythm regardless of amount: a re-priced, trialled, or usage-based subscription, and a
    /// resumed one — a missed period leaves the rhythm intact.
    private func oneRhythm(_ charges: [NormalizedTransaction]) -> ChargeCluster? {
        guard cadenceResolver.timelineCadence(for: charges.map(\.raw.date)) != nil else { return nil }
        return ChargeCluster(charges)
    }

    /// Otherwise amounts separate concurrent subscriptions and one-offs from the same merchant (§7.1).
    private func amountClusters(of charges: [NormalizedTransaction]) -> [ChargeCluster] {
        var clusters: [ChargeCluster] = []
        for charge in charges {
            let amount = charge.raw.amount
            if let index = clusters.firstIndex(where: {
                AmountTolerance.matches($0.first.raw.amount, amount)
            }) {
                clusters[index].append(charge)
            } else {
                clusters.append(ChargeCluster(charge))
            }
        }
        return clusters
    }
}
