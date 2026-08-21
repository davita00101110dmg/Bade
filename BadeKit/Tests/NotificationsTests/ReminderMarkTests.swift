import Core
import Foundation
import Testing

@testable import Notifications

@Suite("Reminder mark")
struct ReminderMarkTests {
    private func reminder(onDay day: Int) -> ChargeReminder {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let date =
            calendar.date(from: DateComponents(year: 2026, month: 9, day: day)) ?? .distantPast
        return ChargeReminder(chargeDate: date, fireDate: date, daysAhead: 1, charges: [])
    }

    /// The one property that matters: a notification already sitting on a phone must not change its
    /// face every time the schedule is recomputed. Swift's own hashing is seeded per process and
    /// would do exactly that.
    @Test func theSameReminderAlwaysTakesTheSameMark() {
        let subject = reminder(onDay: 14)

        #expect(ReminderMark.mark(for: subject) == ReminderMark.mark(for: subject))
        #expect(ReminderMark.mark(for: reminder(onDay: 14)) == ReminderMark.mark(for: subject))
    }

    @Test func everyMarkComesFromThePool() {
        for day in 1...28 {
            #expect(ReminderMark.pool.contains(ReminderMark.mark(for: reminder(onDay: day))))
        }
    }

    /// Spread rather than stuck: a pool that always answers with the same emoji is a fixed emoji
    /// with extra steps.
    @Test func differentDaysDoNotAllGetTheSameMark() {
        let marks = Set((1...28).map { ReminderMark.mark(for: reminder(onDay: $0)) })

        #expect(marks.count >= 3)
    }

    @Test func theTitleOpensWithTheMark() {
        let subject = reminder(onDay: 14)
        let title = ReminderText(locale: Locale(identifier: "en_US")).title(for: subject)

        #expect(title.hasPrefix(ReminderMark.mark(for: subject)))
    }
}
