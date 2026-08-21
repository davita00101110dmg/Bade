import Core
import Foundation

public struct UpcomingState: Equatable {
    public enum Phase: Equatable {
        case loading
        case ready
        case failed
    }

    /// What totals are shown in. Supplied by the composition root, as everywhere else.
    public let currency: String
    public private(set) var phase: Phase = .loading
    public private(set) var subscriptions: [Subscription] = []
    public private(set) var rates = RateBook()
    /// First day of the month on screen.
    public private(set) var month: Date
    /// The day the grid has singled out, if any. The list narrows to it.
    public private(set) var selectedDay: Date?

    let today: Date
    let calendar: Calendar

    public init(currency: String, today: Date = .now, calendar: Calendar = .current) {
        self.currency = currency
        self.today = today
        self.calendar = calendar
        month = calendar.startOfBadeMonth(for: today)
    }

    private var monthEnd: Date {
        calendar.date(byAdding: .month, value: 1, to: month) ?? month
    }

    public var isShowingThisMonth: Bool { month == calendar.startOfBadeMonth(for: today) }

    /// Backwards is allowed because a past month is filled from recorded charges rather than
    /// guessed at. A month Bade never saw simply comes back empty.
    public var canGoBack: Bool { true }

    public var charges: [UpcomingCharge] {
        subscriptions.upcomingCharges(
            from: month, before: monthEnd, today: today, calendar: calendar)
    }

    /// What the list shows: the whole month, or the one day the grid has singled out.
    public var listedDays: [UpcomingDay] {
        guard let selectedDay else { return days }
        return days.filter { calendar.isDate($0.date, inSameDayAs: selectedDay) }
    }

    /// A day can be selected with nothing on it, and saying so beats an empty screen.
    public var isSelectionEmpty: Bool { selectedDay != nil && listedDays.isEmpty }

    public var isEmpty: Bool { charges.isEmpty }

    /// The month's charges in the display currency. Anything with no rate to convert it is
    /// reported separately rather than silently dropped, exactly as the monthly total is.
    public var monthTotal: Decimal {
        charges.reduce(Decimal(0)) { running, charge in running + (converted(charge) ?? 0) }
    }

    public var unconvertibleCount: Int { charges.filter { converted($0) == nil }.count }

    /// One entry per day that has something on it; empty days are absent from the list and shown
    /// only in the grid.
    public var days: [UpcomingDay] {
        Dictionary(grouping: charges) { calendar.startOfDay(for: $0.date) }
            .map { date, charges in
                UpcomingDay(
                    date: date, charges: charges,
                    total: charges.reduce(Decimal(0)) { $0 + (converted($1) ?? 0) },
                    isToday: calendar.isDate(date, inSameDayAs: today))
            }
            .sorted { $0.date < $1.date }
    }

    /// The grid, padded to whole weeks so the columns line up under their weekday headings.
    public var cells: [UpcomingCell] {
        let byDay = Dictionary(grouping: charges) { calendar.startOfDay(for: $0.date) }
        let totals = byDay.mapValues { day in
            day.reduce(Decimal(0)) { running, charge in running + (converted(charge) ?? 0) }
        }
        let heaviest = totals.values.max() ?? 0
        let leading = leadingBlanks
        let length = calendar.range(of: .day, in: .month, for: month)?.count ?? 0
        let total = Int((Double(leading + length) / 7).rounded(.up)) * 7

        return (0..<total).map { index in
            guard index >= leading, index < leading + length else {
                return UpcomingCell(
                    id: index, date: nil, charges: 0, cancelledCharges: 0, weight: 0,
                    isToday: false, isSelected: false)
            }
            let date =
                calendar.date(byAdding: .day, value: index - leading, to: month) ?? month
            let startOfDay = calendar.startOfDay(for: date)
            let onDay = byDay[startOfDay] ?? []
            return UpcomingCell(
                id: index, date: date, charges: onDay.count,
                cancelledCharges: onDay.count { !$0.subscription.isActive },
                weight: Self.share(of: totals[startOfDay] ?? 0, of: heaviest),
                isToday: calendar.isDate(date, inSameDayAs: today),
                isSelected: selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false)
        }
    }

    /// A dot's weight is a proportion, not an amount; the money either side of it stays `Decimal`.
    private static func share(of value: Decimal, of heaviest: Decimal) -> Double {
        guard heaviest > 0, value > 0 else { return 0 }
        return Double(truncating: (value / heaviest) as NSDecimalNumber)
    }

    /// How far the first of the month sits from the start of its week, in the locale's terms —
    /// a week begins on Monday in Georgia and on Sunday in the United States.
    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: month)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    /// Converted at today's rate rather than each charge's own date. Rates are picked by nearest
    /// observation, so per-charge dates made the day totals, the month total and the list's headline
    /// disagree by a few tetri — a difference no reader could account for. What a charge in this
    /// month costs is a question about today.
    public func converted(_ charge: UpcomingCharge) -> Decimal? {
        rates.convert(charge.amount, from: charge.currency, to: currency, on: today)
    }

    public func amount(of charge: UpcomingCharge) -> Decimal {
        converted(charge) ?? charge.amount
    }

    public func currencyCode(of charge: UpcomingCharge) -> String {
        converted(charge) == nil ? charge.currency : currency
    }
}

/// A day the list shows, with everything landing on it.
public struct UpcomingDay: Equatable, Sendable, Identifiable {
    public let date: Date
    public let charges: [UpcomingCharge]
    public let total: Decimal
    public let isToday: Bool

    public var id: Date { date }
}

/// One square in the month grid. Blank squares pad the first and last weeks and carry no date.
public struct UpcomingCell: Equatable, Sendable, Identifiable {
    public let id: Int
    public let date: Date?
    public let charges: Int
    /// Of those, how many belong to a subscription since cancelled. The money still left the
    /// account, so it still counts — but a day made only of them is not money going out again.
    public let cancelledCharges: Int
    /// What this day cost against the heaviest day in the month, 0 to 1. A calendar that marks
    /// every day identically says where charges are; this is what lets it say where the money is.
    public let weight: Double
    public let isToday: Bool
    public let isSelected: Bool

    /// Every charge on this day is from something no longer paid for.
    public var isEntirelyCancelled: Bool { charges > 0 && charges == cancelledCharges }
}

public enum UpcomingIntent: Equatable {
    case appeared
    case loaded([Subscription], RateBook)
    case loadFailed
    case previousMonth
    case nextMonth
    case thisMonth
    case daySelected(Date)
    case showDay(Date)
    case selectionCleared
}

public enum UpcomingEffect: Equatable {
    case load
}

extension UpcomingState {
    public mutating func apply(_ intent: UpcomingIntent) -> UpcomingEffect? {
        switch intent {
        case .appeared:
            return .load

        case .loaded(let subscriptions, let rates):
            self.subscriptions = subscriptions
            self.rates = rates
            phase = .ready
            return nil

        case .loadFailed:
            phase = .failed
            return nil

        // Paging away from a selected day would leave the list showing a day off screen.
        case .previousMonth:
            month = calendar.date(byAdding: .month, value: -1, to: month) ?? month
            selectedDay = nil
            return nil

        case .nextMonth:
            month = calendar.date(byAdding: .month, value: 1, to: month) ?? month
            selectedDay = nil
            return nil

        case .thisMonth:
            month = calendar.startOfBadeMonth(for: today)
            selectedDay = nil
            return nil

        // Arrived at from outside — a tapped reminder — so the month moves too, or the day
        // would be selected somewhere off screen.
        case .showDay(let day):
            month = calendar.startOfBadeMonth(for: day)
            selectedDay = calendar.startOfDay(for: day)
            return nil

        // Tapping the selected day again clears it, so the grid is its own way out.
        case .daySelected(let day):
            let day = calendar.startOfDay(for: day)
            selectedDay = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } == true
                ? nil : day
            return nil

        case .selectionCleared:
            selectedDay = nil
            return nil
        }
    }
}

extension Calendar {
    /// Named to avoid colliding with anything Foundation may add; the plain name is too obvious
    /// to be safe on an extension of a type this widely used.
    func startOfBadeMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
