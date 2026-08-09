import Core
import Foundation

struct AmountHistory: Equatable {
    let priceChanges: [PriceChange]
    let isVariable: Bool
}

/// Sustained steps are price changes (§7.6); constant churn is a usage-based variable amount.
struct AmountHistoryAnalyzer {
    func history(of charges: [RawTransaction]) -> AmountHistory {
        let runs = priceLevels(of: charges)
        if isVolatile(runs, across: charges.count) {
            return AmountHistory(priceChanges: [], isVariable: true)
        }

        let changes = zip(runs, runs.dropFirst()).compactMap { previous, next -> PriceChange? in
            guard let from = previous.last?.amount, let to = next.first else { return nil }
            return PriceChange(date: to.date, from: from, to: to.amount)
        }
        return AmountHistory(priceChanges: changes, isVariable: false)
    }

    /// Two charges can't tell a price rise from churn, so variability needs three.
    private func isVolatile(_ runs: [[RawTransaction]], across count: Int) -> Bool {
        count >= 3 && runs.count(where: { $0.count == 1 }) * 2 > runs.count
    }

    private func priceLevels(of charges: [RawTransaction]) -> [[RawTransaction]] {
        var runs: [[RawTransaction]] = []
        for charge in charges {
            if let previous = runs.last?.last, AmountTolerance.matches(previous.amount, charge.amount) {
                runs[runs.count - 1].append(charge)
            } else {
                runs.append([charge])
            }
        }
        return runs
    }
}
