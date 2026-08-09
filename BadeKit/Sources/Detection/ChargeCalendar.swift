import Core
import Foundation

/// UTC arithmetic — statement dates carry no meaningful local time.
enum ChargeCalendar {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static func days(from start: Date, to end: Date) -> Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func date(after date: Date, cadence: Cadence) -> Date {
        calendar.date(byAdding: cadence.interval, to: date) ?? date
    }
}

extension Cadence {
    fileprivate var interval: DateComponents {
        switch self {
        case .weekly: DateComponents(day: 7)
        case .monthly: DateComponents(month: 1)
        case .quarterly: DateComponents(month: 3)
        case .semiannual: DateComponents(month: 6)
        case .annual: DateComponents(year: 1)
        }
    }
}
