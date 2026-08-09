import Core
import Foundation
import SwiftData

/// SwiftData never leaves this module; everything outside speaks in `ObservedRate`.
@Model
final class ObservedRateRecord {
    #Index<ObservedRateRecord>([\.identity])

    /// One observation is the same as another when it is the same pair, day and rate. Re-importing
    /// an overlapping statement must not stack duplicates.
    @Attribute(.unique) var identity: String
    var date: Date
    var from: String
    var to: String
    var rate: Decimal

    init(_ observed: ObservedRate) {
        identity = Self.identity(of: observed)
        date = observed.date
        from = observed.from
        to = observed.to
        rate = observed.rate
    }

    static func identity(of observed: ObservedRate) -> String {
        "\(observed.from)|\(observed.to)|\(observed.date.timeIntervalSince1970)|\(observed.rate)"
    }

    var observed: ObservedRate {
        ObservedRate(date: date, from: from, to: to, rate: rate)
    }
}
