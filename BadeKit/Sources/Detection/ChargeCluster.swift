import Core
import Foundation

/// A date-ordered, never-empty run of one merchant's charges — a subscription candidate.
struct ChargeCluster {
    private(set) var charges: [NormalizedTransaction]

    init(_ charge: NormalizedTransaction) {
        charges = [charge]
    }

    init?(_ charges: [NormalizedTransaction]) {
        guard !charges.isEmpty else { return nil }
        self.charges = charges.sorted { $0.raw.date < $1.raw.date }
    }

    var first: NormalizedTransaction { charges[0] }
    var last: NormalizedTransaction { charges[charges.count - 1] }
    var dates: [Date] { charges.map(\.raw.date) }
    var occurrences: [RawTransaction] { charges.map(\.raw) }

    mutating func append(_ charge: NormalizedTransaction) {
        charges.append(charge)
    }
}
