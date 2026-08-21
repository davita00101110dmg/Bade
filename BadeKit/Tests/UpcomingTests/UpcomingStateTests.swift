import Core
import Foundation
import Testing

@testable import Upcoming

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    // August 2026 starts on a Saturday; a Monday-first week puts five blanks before it.
    calendar.firstWeekday = 2
    return calendar
}

private func subscription(
    _ merchant: String, next: String, cadence: Cadence = .monthly, amount: String = "10.00",
    currency: String = "GEL", active: Bool = true
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency, cadence: cadence,
        firstChargeDate: day("2026-01-05"), lastChargeDate: day("2026-07-05"),
        nextChargeDate: day(next), isActive: active, confidence: .confident)
}

private func rateBook() -> RateBook {
    var book = RateBook()
    book.record(ObservedRate(date: day("2026-07-05"), from: "USD", to: "GEL", rate: 2.72))
    return book
}

private func state(
    _ subscriptions: [Subscription], today: String = "2026-08-01", rates: RateBook = rateBook()
) -> UpcomingState {
    var state = UpcomingState(currency: "GEL", today: day(today), calendar: utc)
    _ = state.apply(.loaded(subscriptions, rates))
    return state
}

@Suite("Upcoming")
struct UpcomingStateTests {
    /// A subscription marked cancelled stops being projected, but a charge it already took is a
    /// fact and stays counted — which is why this month can be larger than what the list says you
    /// pay. The calendar has to be able to say which charges those were.
    @Test func aCancelledSubscriptionKeepsTheChargeItAlreadyTook() {
        var netflix = subscription("Netflix", next: "2026-08-09", amount: "35.00", active: false)
        netflix.charges = [
            Charge(date: day("2026-08-05"), amount: 35, currency: "GEL", conversion: nil)
        ]
        // Late in the month, so the 5th is genuinely behind us: a charge recorded ahead of today
        // is not a record of anything, and is rightly ignored.
        let subject = state(
            [netflix, subscription("Spotify", next: "2026-08-20", amount: "15.00")],
            today: "2026-08-22")

        #expect(subject.monthTotal == 50)

        let fifth = subject.cells.first { $0.date == day("2026-08-05") }
        #expect(fifth?.charges == 1)
        #expect(fifth?.cancelledCharges == 1)
        #expect(fifth?.isEntirelyCancelled == true)

        // And nothing was projected forward for it: the 9th is empty.
        #expect(subject.cells.first { $0.date == day("2026-08-09") }?.charges == 0)
    }

    @Test func aLiveDayIsNotMarkedCancelled() {
        let subject = state([subscription("Spotify", next: "2026-08-20", amount: "15.00")])
        let twentieth = subject.cells.first { $0.date == day("2026-08-20") }

        #expect(twentieth?.charges == 1)
        #expect(twentieth?.cancelledCharges == 0)
        #expect(twentieth?.isEntirelyCancelled == false)
    }

    @Test func itOpensOnThisMonth() {
        let subject = state([])

        #expect(subject.month == day("2026-08-01"))
        #expect(subject.isShowingThisMonth)
    }

    @Test func theMonthTotalIsWhatLandsInIt() {
        let subject = state([
            subscription("Netflix", next: "2026-08-09", amount: "35.00"),
            subscription("Spotify", next: "2026-08-20", amount: "15.00"),
            subscription("Google One", next: "2026-11-01", cadence: .annual, amount: "50.00"),
        ])

        #expect(subject.monthTotal == 50)
        #expect(subject.charges.count == 2)
    }

    @Test func aweeklyChargeCountsEveryTimeItLands() {
        let subject = state([subscription("Gym", next: "2026-08-03", cadence: .weekly, amount: "10.00")])

        #expect(subject.charges.count == 5)
        #expect(subject.monthTotal == 50)
    }

    @Test func aforeignChargeIsTotalledInTheDisplayCurrency() {
        let subject = state([
            subscription("Netflix", next: "2026-08-09", amount: "10.00", currency: "USD")
        ])

        #expect(subject.monthTotal == Decimal(string: "27.20")!)
        #expect(subject.currencyCode(of: subject.charges[0]) == "GEL")
    }

    /// The same honesty the list applies: an unconvertible charge is reported, never dropped.
    @Test func anUnconvertibleChargeIsCountedSeparatelyAndShownAsBilled() {
        let subject = state(
            [subscription("Netflix", next: "2026-08-09", amount: "9.00", currency: "EUR")],
            rates: RateBook())

        #expect(subject.unconvertibleCount == 1)
        #expect(subject.monthTotal == 0)
        #expect(subject.amount(of: subject.charges[0]) == 9)
        #expect(subject.currencyCode(of: subject.charges[0]) == "EUR")
    }

    @Test func daysCarryTheirOwnChargesAndTotal() {
        let subject = state([
            subscription("Netflix", next: "2026-08-09", amount: "35.00"),
            subscription("Apple", next: "2026-08-09", amount: "5.00"),
            subscription("Spotify", next: "2026-08-20", amount: "15.00"),
        ])

        #expect(subject.days.count == 2)
        #expect(subject.days[0].date == day("2026-08-09"))
        #expect(subject.days[0].charges.count == 2)
        #expect(subject.days[0].total == 40)
        #expect(subject.days[1].date == day("2026-08-20"))
    }

    @Test func todayIsMarkedOnItsDay() {
        let subject = state(
            [subscription("Netflix", next: "2026-08-10", amount: "35.00")], today: "2026-08-10")

        #expect(subject.days[0].isToday)
        #expect(subject.cells.filter(\.isToday).count == 1)
    }

    @Test func theGridCoversTheMonthPaddedToWholeWeeks() {
        let subject = state([])

        #expect(subject.cells.count % 7 == 0)
        #expect(subject.cells.compactMap(\.date).count == 31)
        #expect(subject.cells.prefix(5).allSatisfy { $0.date == nil }, "August 2026 starts on a Saturday")
        #expect(subject.cells[5].date == day("2026-08-01"))
    }

    @Test func agridCellKnowsHowManyChargesLandOnIt() {
        let subject = state([
            subscription("Netflix", next: "2026-08-09"), subscription("Apple", next: "2026-08-09"),
        ])

        #expect(subject.cells.first { $0.date == day("2026-08-09") }?.charges == 2)
        #expect(subject.cells.first { $0.date == day("2026-08-10") }?.charges == 0)
    }

    @Test func pagingMovesTheMonthAndWhatIsInIt() {
        var subject = state([subscription("Google One", next: "2026-11-20", cadence: .annual)])
        #expect(subject.isEmpty)

        for _ in 0..<3 { _ = subject.apply(.nextMonth) }

        #expect(subject.month == day("2026-11-01"))
        #expect(subject.isShowingThisMonth == false)
        #expect(subject.charges.count == 1)
    }

    @Test func pagingBackAndForwardsReturnsWhereItStarted() {
        var subject = state([])

        _ = subject.apply(.nextMonth)
        #expect(subject.month == day("2026-09-01"))
        _ = subject.apply(.previousMonth)

        #expect(subject.month == day("2026-08-01"))
    }

    @Test func returningToThisMonthIsOneTapFromAnywhere() {
        var subject = state([])
        for _ in 0..<5 { _ = subject.apply(.nextMonth) }

        _ = subject.apply(.thisMonth)

        #expect(subject.isShowingThisMonth)
    }

    /// A past month is filled from what was recorded, never from the rhythm.
    @Test func apastMonthShowsRecordedChargesOnly() {
        var netflix = subscription("Netflix", next: "2026-08-09", amount: "35.00")
        netflix.charges = [
            Charge(date: day("2026-07-09"), amount: 35, currency: "GEL", conversion: nil)
        ]
        var subject = state([netflix])

        _ = subject.apply(.previousMonth)

        #expect(subject.month == day("2026-07-01"))
        #expect(subject.charges.map(\.date) == [day("2026-07-09")])
    }

    @Test func amonthBadeNeverSawStaysEmpty() {
        var subject = state([subscription("Netflix", next: "2026-08-09")])

        _ = subject.apply(.previousMonth)

        #expect(subject.isEmpty, "nothing recorded, and nothing invented")
    }

    @Test func selectingADayNarrowsTheListAndClearsAgain() {
        var subject = state([
            subscription("Netflix", next: "2026-08-09", amount: "35.00"),
            subscription("Spotify", next: "2026-08-20", amount: "15.00"),
        ])

        _ = subject.apply(.daySelected(day("2026-08-09")))
        #expect(subject.listedDays.map(\.date) == [day("2026-08-09")])
        #expect(subject.cells.first { $0.date == day("2026-08-09") }?.isSelected == true)

        _ = subject.apply(.daySelected(day("2026-08-09")))
        #expect(subject.selectedDay == nil)
        #expect(subject.listedDays.count == 2)
    }

    @Test func selectingADayWithNothingOnItSaysSo() {
        var subject = state([subscription("Netflix", next: "2026-08-09")])

        _ = subject.apply(.daySelected(day("2026-08-12")))

        #expect(subject.isSelectionEmpty)
        #expect(subject.listedDays.isEmpty)
    }

    @Test func turningTheMonthDropsTheSelection() {
        var subject = state([subscription("Netflix", next: "2026-08-09")])
        _ = subject.apply(.daySelected(day("2026-08-09")))

        _ = subject.apply(.nextMonth)

        #expect(subject.selectedDay == nil)
    }

    @Test func cancelledSubscriptionsAreNotComing() {
        let subject = state([subscription("Netflix", next: "2026-08-09", active: false)])

        #expect(subject.isEmpty)
        #expect(subject.monthTotal == 0)
    }

    @Test func afailedReadSaysSoRatherThanLookingEmpty() {
        var subject = UpcomingState(currency: "GEL", today: day("2026-08-10"), calendar: utc)

        #expect(subject.apply(.appeared) == .load)
        #expect(subject.apply(.loadFailed) == nil)
        #expect(subject.phase == .failed)
    }
}
