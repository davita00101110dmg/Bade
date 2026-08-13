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
        calendar.date(byAdding: cadence.interval(times: 1), to: date) ?? date
    }

    /// Every day the cadence falls on across `range`, each measured from `phase` rather than
    /// stepped: adding a month repeatedly from the 31st clamps to the 28th and never climbs back.
    /// The phase may sit anywhere in the range, so projections run backwards from it as well.
    static func projections(phase: Date, covering range: ClosedRange<Date>, cadence: Cadence)
        -> [Date]
    {
        func periods(from start: Date, to end: Date) -> Int {
            let value = calendar.dateComponents([cadence.unit], from: start, to: end)
                .value(for: cadence.unit) ?? 0
            return max(0, value) / cadence.period + 1
        }
        let first = -periods(from: range.lowerBound, to: phase)
        let last = periods(from: phase, to: range.upperBound)
        return (first...last).compactMap {
            calendar.date(byAdding: cadence.interval(times: $0), to: phase)
        }
    }
}

extension Cadence {
    fileprivate var unit: Calendar.Component { self == .weekly ? .day : .month }

    fileprivate var period: Int {
        switch self {
        case .weekly: 7
        case .monthly: 1
        case .quarterly: 3
        case .semiannual: 6
        case .annual: 12
        }
    }

    fileprivate func interval(times: Int) -> DateComponents {
        unit == .day
            ? DateComponents(day: period * times) : DateComponents(month: period * times)
    }
}
