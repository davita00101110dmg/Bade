import Core
import Foundation

/// Clusters day-deltas into a cadence (spec §7.3).
struct CadenceResolver {
    /// Every gap agrees — a subscription charging without interruption.
    func uniformCadence(for dates: [Date]) -> Cadence? {
        guard let candidate = cadence(for: dates) else { return nil }
        return deltas(of: dates).allSatisfy(candidate.approximateDays.contains) ? candidate : nil
    }

    /// The cadence most gaps agree on, so a cancelled-then-resumed subscription still resolves.
    func cadence(for dates: [Date]) -> Cadence? {
        let deltas = deltas(of: dates)
        guard !deltas.isEmpty else { return nil }

        var matches: [Cadence: Int] = [:]
        for delta in deltas {
            guard let cadence = Cadence.allCases.first(where: { $0.approximateDays.contains(delta) })
            else { continue }
            matches[cadence, default: 0] += 1
        }

        guard let best = Cadence.allCases.max(by: { matches[$0, default: 0] < matches[$1, default: 0] }),
            let count = matches[best], count * 2 >= deltas.count
        else { return nil }
        return best
    }

    private func deltas(of dates: [Date]) -> [Int] {
        let ordered = dates.sorted()
        return zip(ordered, ordered.dropFirst()).map(ChargeCalendar.days(from:to:))
    }
}
