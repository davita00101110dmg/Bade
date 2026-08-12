import Core
import Foundation
import SwiftData

/// SwiftData never leaves this module; everything outside speaks in `OfficialRate`.
@Model
final class OfficialRateRecord {
    #Index<OfficialRateRecord>([\.identity])

    /// A currency on a day has exactly one official rate, so re-fetching cannot stack duplicates.
    @Attribute(.unique) var identity: String
    var date: Date
    var currency: String
    var rate: Decimal

    init(_ official: OfficialRate) {
        identity = Self.identity(of: official)
        date = official.date
        currency = official.currency
        rate = official.rate
    }

    static func identity(of official: OfficialRate) -> String {
        "\(official.currency)|\(official.date.timeIntervalSince1970)"
    }

    var official: OfficialRate {
        OfficialRate(date: date, currency: currency, rate: rate)
    }
}
