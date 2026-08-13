import Foundation
import Testing

@testable import Core

/// A statement ends when it ends. A charge due three days later is real, unrecorded, and by the time
/// anyone opens the app it is in the past — so "when next" cannot be answered by reading the stored
/// date out loud.
@Suite("Next charge from today")
struct NextChargeTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    private func subscription(_ cadence: Cadence, next: Date) -> Subscription {
        Subscription(
            merchant: "Setanta", amount: 15, currency: "GEL", cadence: cadence,
            firstChargeDate: next, lastChargeDate: next, nextChargeDate: next,
            confidence: .confident)
    }

    /// The real one: a statement ending 7 August leaves a charge due the 10th, read on the 13th.
    @Test func aDateLeftBehindByTheStatementRollsForward() {
        let setanta = subscription(.monthly, next: date(2026, 8, 10))

        #expect(
            setanta.nextCharge(onOrAfter: date(2026, 8, 13), calendar: calendar)
                == date(2026, 9, 10))
    }

    @Test func adateStillToComeIsLeftAlone() {
        let setanta = subscription(.monthly, next: date(2026, 8, 20))

        #expect(
            setanta.nextCharge(onOrAfter: date(2026, 8, 13), calendar: calendar)
                == date(2026, 8, 20))
    }

    /// Due today is still due today; a charge does not become next month's at breakfast.
    @Test func todayIsNotPast() {
        let setanta = subscription(.monthly, next: date(2026, 8, 13))

        #expect(
            setanta.nextCharge(onOrAfter: date(2026, 8, 13), calendar: calendar)
                == date(2026, 8, 13))
    }

    /// Months of arrears at once, not one period at a time.
    @Test func aLongAbandonedDateCatchesUpInOneGo() {
        let setanta = subscription(.monthly, next: date(2025, 3, 10))

        #expect(
            setanta.nextCharge(onOrAfter: date(2026, 8, 13), calendar: calendar)
                == date(2026, 9, 10))
    }

    /// Measured from the anchor, so February cannot drag the 31st down to the 28th for good.
    @Test func aMonthEndChargeKeepsItsDay() {
        let adobe = subscription(.monthly, next: date(2026, 1, 31))

        #expect(
            adobe.nextCharge(onOrAfter: date(2026, 3, 1), calendar: calendar) == date(2026, 3, 31))
    }

    @Test(arguments: [Cadence.weekly, .monthly, .quarterly, .semiannual, .annual])
    func everyCadenceLandsInTheFuture(cadence: Cadence) {
        let subject = subscription(cadence, next: date(2024, 6, 15))

        #expect(subject.nextCharge(onOrAfter: date(2026, 8, 13), calendar: calendar) >= date(2026, 8, 13))
    }
}
