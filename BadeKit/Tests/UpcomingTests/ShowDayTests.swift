import Core
import Foundation
import Testing

@testable import Upcoming

/// Arriving from a tapped reminder: the day it announced has to be the day on screen, whichever
/// month that day belongs to.
@Suite("Opening on a day")
struct ShowDayTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    private func state(today: Date) -> UpcomingState {
        UpcomingState(currency: "GEL", today: today, calendar: calendar)
    }

    @Test func aDayInThisMonthIsSelected() {
        var subject = state(today: date(2026, 8, 12))

        #expect(subject.apply(.showDay(date(2026, 8, 20))) == nil)
        #expect(subject.selectedDay == date(2026, 8, 20))
    }

    /// A reminder for the 1st goes out in the month before, so the calendar travels with it.
    @Test func aDayInAnotherMonthMovesTheMonthToo() {
        var subject = state(today: date(2026, 8, 31))
        let target = date(2026, 9, 1)

        _ = subject.apply(.showDay(target))

        #expect(subject.selectedDay == target)
        #expect(calendar.component(.month, from: subject.month) == 9)
    }

    /// Only the day matters: a reminder fires at 09:00, but the charge is a day.
    @Test func theTimeOfDayIsDiscarded() throws {
        var subject = state(today: date(2026, 8, 12))
        let noon = try #require(
            calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date(2026, 8, 20)))

        _ = subject.apply(.showDay(noon))

        #expect(subject.selectedDay == date(2026, 8, 20))
    }
}
