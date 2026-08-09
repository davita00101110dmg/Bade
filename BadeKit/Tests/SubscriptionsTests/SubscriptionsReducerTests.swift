import Core
import Foundation
import Testing

@testable import Subscriptions

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

private func subscription(
    _ merchant: String, _ amount: String, _ currency: String = "GEL",
    cadence: Cadence = .monthly, next: String = "2026-09-05", active: Bool = true
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency, cadence: cadence,
        firstChargeDate: day("2026-01-05"), lastChargeDate: day("2026-08-05"),
        nextChargeDate: day(next), isActive: active, confidence: .confident)
}

private func rateBook() -> RateBook {
    var book = RateBook()
    book.record(ObservedRate(date: day("2026-08-05"), from: "USD", to: "GEL", rate: 2.72))
    return book
}

@Suite("Subscriptions state")
struct SubscriptionsStateTests {
    private func state(
        _ stored: [Subscription], rates: RateBook = rateBook()
    ) -> SubscriptionsState {
        var state = SubscriptionsState(currency: "GEL")
        _ = state.apply(.loaded(stored, rates))
        return state
    }

    @Test func appearingLoads() {
        var subject = SubscriptionsState(currency: "GEL")
        #expect(subject.apply(.appeared) == .load)
        #expect(subject.phase == .loading)
    }

    @Test func theTotalNormalisesEveryCadenceToAMonth() {
        let subject = state([
            subscription("Spotify", "15.00"),
            subscription("Google One", "60.00", cadence: .annual),
        ])

        #expect(subject.monthlyTotal == 20)
        #expect(subject.annualTotal == 240)
    }

    @Test func theTotalConvertsForeignChargesAtTheObservedRate() {
        let subject = state([
            subscription("ChatGPT", "20.00", "USD"),
            subscription("MAGTICOM", "35.00"),
        ])

        #expect(subject.monthlyTotal == Decimal(string: "89.40")!)
    }

    /// Cancelled subscriptions are not spend, and the list must agree with the number above it.
    @Test func cancelledSubscriptionsLeaveBothTheListAndTheTotal() {
        let subject = state([
            subscription("Spotify", "15.00"),
            subscription("Netflix", "35.00", active: false),
        ])

        #expect(subject.count == 1)
        #expect(subject.rows.map(\.subscription.merchant) == ["Spotify"])
        #expect(subject.monthlyTotal == 15)
    }

    @Test func costOrdersBiggestFirst() {
        let subject = state([
            subscription("Small", "5.00"),
            subscription("Big", "50.00"),
            subscription("Middle", "20.00"),
        ])

        #expect(subject.rows.map(\.subscription.merchant) == ["Big", "Middle", "Small"])
    }

    /// An annual subscription costs less per month than its sticker price suggests, and the list
    /// is ordered by what it actually costs a month.
    @Test func costOrdersOnMonthlyEquivalentNotStickerPrice() {
        let subject = state([
            subscription("Yearly", "120.00", cadence: .annual),
            subscription("Monthly", "15.00"),
        ])

        #expect(subject.rows.map(\.subscription.merchant) == ["Monthly", "Yearly"])
    }

    @Test func sortingSwitchesWithoutReloading() {
        var subject = state([
            subscription("Zeta", "50.00", next: "2026-09-20"),
            subscription("Alpha", "5.00", next: "2026-09-01"),
        ])

        #expect(subject.apply(.sortChanged(.name)) == nil)
        #expect(subject.rows.map(\.subscription.merchant) == ["Alpha", "Zeta"])

        _ = subject.apply(.sortChanged(.nextCharge))
        #expect(subject.rows.map(\.subscription.merchant) == ["Alpha", "Zeta"])

        _ = subject.apply(.sortChanged(.cost))
        #expect(subject.rows.map(\.subscription.merchant) == ["Zeta", "Alpha"])
    }

    /// Nothing is dropped for want of a rate — it is counted separately and said out loud.
    @Test func anUnconvertibleSubscriptionIsReportedNotHidden() {
        let subject = state([
            subscription("Spotify", "15.00"),
            subscription("REAL-DEBRID", "9.00", "EUR"),
        ])

        #expect(subject.monthlyTotal == 15)
        #expect(subject.unconvertibleCount == 1)
        #expect(subject.rows.count == 2, "it still has to appear in the list")
    }

    @Test func anUnconvertibleRowSortsLastRatherThanFree() {
        let subject = state([
            subscription("Euro", "9.00", "EUR"),
            subscription("Lari", "1.00"),
        ])

        #expect(subject.rows.map(\.subscription.merchant) == ["Lari", "Euro"])
    }

    @Test func anUnconvertibleRowKeepsItsOwnCurrency() {
        let subject = state([subscription("REAL-DEBRID", "9.00", "EUR")])
        let row = subject.rows[0]

        #expect(row.displayCurrency("GEL") == "EUR")
        #expect(row.displayAmount(in: "GEL") == 9)
    }

    @Test func leavingIsAnIntentLikeAnythingElse() {
        var subject = state([subscription("Spotify", "15.00")])

        #expect(subject.apply(.importTapped) == .exit(.importStatement))
    }

    @Test func aFailedLoadSaysSoRatherThanShowingZero() {
        var subject = SubscriptionsState(currency: "GEL")
        _ = subject.apply(.appeared)

        #expect(subject.apply(.loadFailed) == nil)
        #expect(subject.phase == .failed)
        #expect(subject.isEmpty == false, "failure is not emptiness")
    }
}

/// A swipe is already deliberate, so one row goes immediately. Clearing everything does not.
@Suite("Subscriptions deletion")
struct SubscriptionsDeletionTests {
    private func state(_ stored: [Subscription]) -> SubscriptionsState {
        var state = SubscriptionsState(currency: "GEL")
        _ = state.apply(.loaded(stored, rateBook()))
        return state
    }

    @Test func aSwipeDeletesTheRowItWasMadeOn() {
        var subject = state([
            subscription("Spotify", "15.00"), subscription("Netflix", "35.00"),
        ])
        let target = subject.all[1]

        #expect(subject.apply(.deleteTapped(target)) == .delete(target.id))
    }

    /// Nothing modal interrupts a swipe, so the row never springs shut under an alert.
    @Test func deletingOneRowAsksNothing() {
        var subject = state([subscription("Spotify", "15.00")])

        _ = subject.apply(.deleteTapped(subject.all[0]))

        #expect(subject.isConfirmingDeleteAll == false)
    }

    @Test func clearingEverythingAsksFirst() {
        var subject = state([subscription("Spotify", "15.00")])

        #expect(subject.apply(.deleteAllRequested) == nil)
        #expect(subject.isConfirmingDeleteAll)
        #expect(subject.apply(.deleteAllConfirmed) == .deleteEverything)
        #expect(subject.isConfirmingDeleteAll == false)
    }

    @Test func dismissingClearsEverythingNothing() {
        var subject = state([subscription("Spotify", "15.00")])
        _ = subject.apply(.deleteAllRequested)

        #expect(subject.apply(.confirmationDismissed) == nil)
        #expect(subject.isConfirmingDeleteAll == false)
    }

    @Test func aDeletionReloadsRatherThanGuessingTheNewList() {
        var subject = state([subscription("Spotify", "15.00")])

        #expect(subject.apply(.deletionFinished) == .load)
    }

    /// This screen is only ever shown over data; emptied, it hands the root back to Welcome.
    @Test func emptyingTheStoreReturnsToWelcome() {
        var subject = SubscriptionsState(currency: "GEL")

        #expect(subject.apply(.loaded([], RateBook())) == .exit(.dataCleared))
    }
}
