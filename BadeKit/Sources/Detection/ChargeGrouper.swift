import Core
import Foundation

/// Splits one merchant's charges into subscription candidates.
struct ChargeGrouper {
    private let cadenceResolver = CadenceResolver()

    func clusters(for charges: [NormalizedTransaction]) -> [ChargeCluster] {
        let ordered = charges.sorted { $0.raw.date < $1.raw.date }
        if let uniform = uniformTimeline(ordered) { return [uniform] }
        return amountClusters(of: ordered)
    }

    /// One unbroken rhythm regardless of amount: a re-priced, trialled, or usage-based subscription.
    private func uniformTimeline(_ charges: [NormalizedTransaction]) -> ChargeCluster? {
        guard charges.count >= 2,
            cadenceResolver.uniformCadence(for: charges.map(\.raw.date)) != nil
        else { return nil }
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
