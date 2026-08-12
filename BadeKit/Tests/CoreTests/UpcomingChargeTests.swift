import Foundation
import Testing

@testable import Core

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

private func subscription(
    _ merchant: String, next: String, cadence: Cadence = .monthly, active: Bool = true,
    amount: String = "10.00"
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: "GEL", cadence: cadence,
        firstChargeDate: day("2026-01-05"), lastChargeDate: day("2026-07-05"),
        nextChargeDate: day(next), isActive: active, confidence: .confident)
}

private func charges(
    _ subscriptions: [Subscription], from: String = "2026-08-01", before: String = "2026-09-01",
    today: String = "2026-08-01"
) -> [UpcomingCharge] {
    subscriptions.upcomingCharges(
        from: day(from), before: day(before), today: day(today), calendar: utc)
}

@Suite("Projecting upcoming charges")
struct UpcomingChargeTests {
    @Test func amonthlySubscriptionAppearsOnceInAMonth() {
        let projected = charges([subscription("Netflix", next: "2026-08-09")])

        #expect(projected.count == 1)
        #expect(projected[0].date == day("2026-08-09"))
        #expect(projected[0].subscription.merchant == "Netflix")
    }

    @Test func aweeklySubscriptionRepeatsAcrossTheMonth() {
        let projected = charges([subscription("Gym", next: "2026-08-03", cadence: .weekly)])

        #expect(projected.map(\.date) == ["2026-08-03", "2026-08-10", "2026-08-17", "2026-08-24", "2026-08-31"].map(day))
    }

    @Test func anannualSubscriptionMissesMostMonthsEntirely() {
        let netflix = subscription("Google One", next: "2026-11-20", cadence: .annual)

        #expect(charges([netflix]).isEmpty)
        #expect(charges([netflix], from: "2026-11-01", before: "2026-12-01").count == 1)
    }

    /// The statement is old, not the subscription dead — lapse is judged against the statement.
    @Test func astaleDateIsRolledForwardRatherThanDropped() {
        let projected = charges([subscription("Netflix", next: "2026-02-09")])

        #expect(projected.map(\.date) == [day("2026-08-09")])
    }

    @Test func rollingForwardKeepsTheDayOfTheMonth() {
        let projected = charges(
            [subscription("Netflix", next: "2025-01-31")], from: "2026-08-01",
            before: "2026-09-01")

        #expect(projected.map(\.date) == [day("2026-08-31")])
    }

    @Test func cancelledSubscriptionsAreNotComing() {
        #expect(charges([subscription("Netflix", next: "2026-08-09", active: false)]).isEmpty)
    }

    /// Nothing is projected backwards: a day already gone is only shown if a statement recorded it.
    @Test func nothingIsProjectedIntoThePast() {
        let projected = charges(
            [subscription("Netflix", next: "2026-08-09")], today: "2026-08-20")

        #expect(projected.isEmpty)
    }

    @Test func apastMonthShowsWhatWasActuallyCharged() {
        var netflix = subscription("Netflix", next: "2026-08-09")
        netflix.charges = [
            Charge(date: day("2026-07-09"), amount: 35, currency: "GEL", conversion: nil)
        ]

        let projected = charges(
            [netflix], from: "2026-07-01", before: "2026-08-01", today: "2026-08-20")

        #expect(projected.map(\.date) == [day("2026-07-09")])
        #expect(projected.first?.amount == 35)
    }

    /// A charge that happened is a fact about the money, whatever became of the subscription.
    @Test func arecordedChargeShowsEvenOnceCancelled() {
        var netflix = subscription("Netflix", next: "2026-08-09", active: false)
        netflix.charges = [
            Charge(date: day("2026-07-09"), amount: 35, currency: "GEL", conversion: nil)
        ]

        #expect(
            charges([netflix], from: "2026-07-01", before: "2026-08-01", today: "2026-08-20")
                .count == 1)
    }

    /// The recorded price is what was billed then, not what the subscription costs now.
    @Test func arecordedChargeKeepsItsOwnPrice() {
        var netflix = subscription("Netflix", next: "2026-08-09", amount: "45.00")
        netflix.charges = [
            Charge(date: day("2026-07-09"), amount: 35, currency: "GEL", conversion: nil)
        ]

        let projected = charges(
            [netflix], from: "2026-07-01", before: "2026-08-01", today: "2026-08-20")

        #expect(projected.first?.amount == 35)
    }

    /// The two halves must not both claim the same day.
    @Test func arecordedChargeIsNotAlsoProjected() {
        var netflix = subscription("Netflix", next: "2026-08-09")
        netflix.charges = [
            Charge(date: day("2026-08-09"), amount: 35, currency: "GEL", conversion: nil)
        ]

        #expect(charges([netflix], today: "2026-08-20").count == 1)
    }

    @Test func chargesComeBackInDateOrder() {
        let projected = charges([
            subscription("Netflix", next: "2026-08-20"),
            subscription("Spotify", next: "2026-08-03"),
            subscription("MAGTICOM", next: "2026-08-11"),
        ])

        #expect(projected.map(\.subscription.merchant) == ["Spotify", "MAGTICOM", "Netflix"])
    }

    @Test func twoChargesOnOneDayAreOrderedByName() {
        let projected = charges([
            subscription("Netflix", next: "2026-08-09"), subscription("Apple", next: "2026-08-09"),
        ])

        #expect(projected.map(\.subscription.merchant) == ["Apple", "Netflix"])
    }

    /// Half open, so a charge on the first of next month belongs to next month.
    @Test func theWindowExcludesItsEnd() {
        let projected = charges([subscription("Netflix", next: "2026-09-01")])

        #expect(projected.isEmpty)
    }

    @Test func awindowWithNothingInItIsEmptyRatherThanWrong() {
        #expect(charges([]).isEmpty)
    }

    @Test func eachProjectedChargeIsDistinct() {
        let projected = charges([subscription("Gym", next: "2026-08-03", cadence: .weekly)])

        #expect(Set(projected.map(\.id)).count == projected.count)
    }

    /// A date so stale that rolling forward would never finish must still terminate.
    @Test func adecadeOfStalenessStillTerminates() {
        let projected = charges([subscription("Gym", next: "1990-01-01", cadence: .weekly)])

        #expect(projected.isEmpty)
    }
}
