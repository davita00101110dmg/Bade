import Core
import Foundation
import Testing

@testable import Notifications

@Suite("Reminder plan")
struct ReminderPlanTests {
    /// Fixed zone: a fire time is only meaningful against the calendar that produced it.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0)
        -> Date
    {
        calendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
            ?? .distantPast
    }

    private func subscription(
        _ merchant: String, _ amount: String, _ currency: String = "GEL",
        _ cadence: Cadence = .monthly, next: Date, isActive: Bool = true
    ) -> Subscription {
        Subscription(
            merchant: merchant, amount: Decimal(string: amount) ?? 0, currency: currency,
            cadence: cadence, firstChargeDate: next, lastChargeDate: next, nextChargeDate: next,
            isActive: isActive, confidence: .confident)
    }

    private func plan(
        _ subscriptions: [Subscription], _ lead: ReminderLead, at timeOfDay: Int = 9 * 60,
        now: Date
    ) -> [ChargeReminder] {
        ReminderPlan.reminders(
            for: subscriptions,
            preference: ReminderPreference(lead: lead, timeOfDay: timeOfDay),
            from: now, calendar: calendar)
    }

    @Test func offSchedulesNothing() {
        let netflix = subscription("Netflix", "39", next: date(2026, 8, 20))
        #expect(plan([netflix], .off, now: date(2026, 8, 12, 10)).isEmpty)
    }

    @Test func aDayAheadFiresTheMorningBefore() throws {
        let netflix = subscription("Netflix", "39", next: date(2026, 8, 20))
        let reminders = plan([netflix], .oneDay, now: date(2026, 8, 12, 10))
        let first = try #require(reminders.first)

        #expect(first.chargeDate == date(2026, 8, 20))
        #expect(first.fireDate == date(2026, 8, 19, 9))
        #expect(first.daysAhead == 1)
    }

    @Test func theChosenTimeOfDayIsUsed() throws {
        let netflix = subscription("Netflix", "39", next: date(2026, 8, 20))
        let reminders = plan([netflix], .sameDay, at: 21 * 60 + 30, now: date(2026, 8, 12, 10))
        #expect(try #require(reminders.first).fireDate == date(2026, 8, 20, 21, 30))
    }

    /// Otherwise iOS fires it on the spot, announcing a charge as upcoming the morning it lands.
    @Test func aMomentAlreadyPassedIsNotScheduled() {
        let netflix = subscription("Netflix", "39", next: date(2026, 8, 13))
        let reminders = plan([netflix], .oneDay, now: date(2026, 8, 12, 10))

        #expect(reminders.allSatisfy { $0.chargeDate > date(2026, 8, 13) })
    }

    @Test func chargesOnOneDayBecomeOneReminder() throws {
        let day = date(2026, 8, 20)
        let subscriptions = [
            subscription("Spotify", "24.90", next: day),
            subscription("Netflix", "39", next: day),
            subscription("MAGTICOM", "35", next: day),
        ]
        let reminders = plan(subscriptions, .oneDay, now: date(2026, 8, 12, 10))
        let first = try #require(reminders.first)

        #expect(first.charges.count == 3)
        #expect(first.merchants == ["MAGTICOM", "Netflix", "Spotify"])
        #expect(first.total?.amount == Decimal(string: "98.90"))
        #expect(first.total?.currency == "GEL")
    }

    @Test func aMixedCurrencyDayHasNoTotal() throws {
        let day = date(2026, 8, 20)
        let subscriptions = [
            subscription("Netflix", "12.99", "USD", next: day),
            subscription("MAGTICOM", "35", "GEL", next: day),
        ]
        let reminders = plan(subscriptions, .oneDay, now: date(2026, 8, 12, 10))

        #expect(try #require(reminders.first).total == nil)
    }

    @Test func aCancelledSubscriptionIsNotAnnounced() {
        let netflix = subscription("Netflix", "39", next: date(2026, 8, 20), isActive: false)
        #expect(plan([netflix], .oneDay, now: date(2026, 8, 12, 10)).isEmpty)
    }

    @Test func remindersComeSoonestFirst() {
        let subscriptions = [
            subscription("Later", "10", next: date(2026, 9, 5)),
            subscription("Sooner", "10", next: date(2026, 8, 20)),
        ]
        let reminders = plan(subscriptions, .oneDay, now: date(2026, 8, 12, 10))

        #expect(reminders.map(\.fireDate) == reminders.map(\.fireDate).sorted())
    }

    /// iOS keeps only the 64 soonest pending notifications; over the cap it drops the rest itself.
    @Test func neverSchedulesMoreThaniOSKeeps() {
        let subscriptions = (1...40).map {
            subscription("Weekly \($0)", "10", "GEL", .weekly, next: date(2026, 8, 13 + $0))
        }
        let reminders = plan(subscriptions, .oneDay, now: date(2026, 8, 12, 10))

        #expect(reminders.count == ReminderPlan.limit)
    }

    /// The cap is what a schedule runs out of, never the horizon. At a year it was the other way
    /// round for anyone with a handful of subscriptions: two monthly ones spent 24 of the 64 slots
    /// and went quiet after twelve months with 40 slots never used.
    @Test func twoSubscriptionsStillSpendTheWholeCap() {
        let subscriptions = [
            subscription("Netflix", "39", next: date(2026, 9, 4)),
            subscription("Spotify", "24.90", next: date(2026, 9, 18)),
        ]
        let reminders = plan(subscriptions, .oneDay, now: date(2026, 8, 12, 10))

        #expect(reminders.count == ReminderPlan.limit)
    }

    /// The sharpest form of the same bug: an annual subscription charges once inside a one-year
    /// window, so an annual-only subscriber was told once and then never again.
    @Test func anAnnualSubscriptionIsAnnouncedMoreThanOnce() {
        let domain = subscription("Domain", "60", "GEL", .annual, next: date(2026, 9, 4))
        let reminders = plan([domain], .oneDay, now: date(2026, 8, 12, 10))

        #expect(reminders.count == ReminderPlan.horizonYears)
    }

    /// February clamps a charge on the 31st to the 28th. Measured from a fixed anchor the day comes
    /// back; stepped one month at a time it never would.
    @Test func aMonthEndChargeComesBackAfterFebruary() throws {
        let adobe = subscription("Adobe", "19.99", next: date(2026, 8, 31))
        let charges = plan([adobe], .oneDay, now: date(2026, 8, 12, 10)).map(\.chargeDate)
        let march = try #require(charges.first { calendar.component(.month, from: $0) == 3 })

        #expect(calendar.component(.day, from: march) == 31)
    }
}
