import Core
import Foundation

/// Clusters charges into a cadence (spec §7.3).
struct CadenceResolver {
    /// The cadence a merchant's whole timeline keeps, fitted to a fixed phase rather than measured
    /// gap to gap.
    ///
    /// A chain of day-deltas breaks on one late charge, and a subscription billing on the 31st
    /// produces gaps of 28, 31 and 32 from nothing but the calendar; a phase absorbs both. A missed
    /// period is simply an unclaimed projection, so a resumed subscription still reads as one
    /// timeline. Each charge claims a projection of its own, so a burst of same-day charges cannot
    /// pass for a rhythm.
    ///
    /// Nearly every charge has to be on rhythm, not merely most, because the grouper asks this
    /// before it separates a merchant's charges by amount: a subscription mixed in with one-off
    /// purchases from the same merchant must fail here, or the two merge and neither is reported.
    /// At four charges that means all four; the allowance only opens up from five.
    func timelineCadence(for dates: [Date]) -> Cadence? {
        guard dates.count >= 2 else { return nil }
        // Longest first, so charges a quarter apart are quarterly, not monthly with months missing.
        return Cadence.allCases.reversed().first { fit(dates, to: $0) >= Self.minimumOnRhythm }
    }

    private static let minimumOnRhythm = 0.8

    /// The cadence most gaps agree on, so a cancelled-then-resumed subscription still resolves.
    /// Applied to a cluster the grouper has already settled, where the merchant and amount are
    /// known to agree and a looser reading of the dates is safe.
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

    /// The best any charge can do as the phase. Phasing on the first charge alone is fragile: a
    /// trial, a part-month, or an off-cycle first charge would throw every projection out.
    private func fit(_ dates: [Date], to cadence: Cadence) -> Double {
        let ordered = dates.sorted()
        guard let first = ordered.first, let last = ordered.last else { return 0 }
        let span = first...last
        return ordered.map { fit(ordered, to: cadence, phasedOn: $0, covering: span) }.max() ?? 0
    }

    /// The share of charges landing within slack of a projection no other charge has taken.
    private func fit(
        _ ordered: [Date], to cadence: Cadence, phasedOn phase: Date,
        covering span: ClosedRange<Date>
    ) -> Double {
        var projections = ChargeCalendar.projections(phase: phase, covering: span, cadence: cadence)

        var matched = 0
        for date in ordered {
            func distance(_ index: Int) -> Int {
                abs(ChargeCalendar.days(from: projections[index], to: date))
            }
            guard let nearest = projections.indices.min(by: { distance($0) < distance($1) }),
                distance(nearest) <= cadence.slack
            else { continue }
            projections.remove(at: nearest)
            matched += 1
        }
        return Double(matched) / Double(ordered.count)
    }

    private func deltas(of dates: [Date]) -> [Int] {
        let ordered = dates.sorted()
        return zip(ordered, ordered.dropFirst()).map(ChargeCalendar.days(from:to:))
    }
}

extension Cadence {
    /// How far a charge may fall from the day it was due. A retry or a weekend shift moves one by a
    /// few days; month lengths are the phase's problem, not this window's. Four days is what a real
    /// monthly telecom bill needed — its gaps run 31 and 34.
    fileprivate var slack: Int {
        switch self {
        case .weekly: 1
        case .monthly: 4
        case .quarterly: 6
        case .semiannual: 8
        case .annual: 12
        }
    }
}
