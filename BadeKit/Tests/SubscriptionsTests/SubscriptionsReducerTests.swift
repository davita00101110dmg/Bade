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
        _ stored: [Subscription], rates: RateBook = rateBook(), today: Date = day("2026-08-13")
    ) -> SubscriptionsState {
        var state = SubscriptionsState(currency: "GEL", today: today)
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

    /// Settings changes the currency under a screen that is already open. It used to be rebuilt
    /// around the new one, which threw away everything it had loaded and replayed the arrival.
    @Test func changingTheCurrencyReconvertsWithoutReloading() {
        var subject = state([
            subscription("ChatGPT", "20.00", "USD"),
            subscription("MAGTICOM", "35.00"),
        ])

        #expect(subject.apply(.currencyChanged("USD")) == nil)

        #expect(subject.currency == "USD")
        #expect(subject.phase == .ready)
        #expect(subject.rows.count == 2)

        var total = subject.monthlyTotal
        var shown = Decimal()
        NSDecimalRound(&shown, &total, 2, .plain)
        #expect(shown == Decimal(string: "32.87")!)
    }

    @Test func theTotalConvertsForeignChargesAtTheObservedRate() {
        let subject = state([
            subscription("ChatGPT", "20.00", "USD"),
            subscription("MAGTICOM", "35.00"),
        ])

        #expect(subject.monthlyTotal == Decimal(string: "89.40")!)
    }

    /// Cancelled subscriptions are not spend, so they leave the total and the live list.
    @Test func cancelledSubscriptionsLeaveTheTotal() {
        let subject = state([
            subscription("Spotify", "15.00"),
            subscription("Netflix", "35.00", active: false),
        ])

        #expect(subject.count == 1)
        #expect(subject.rows.map(\.subscription.merchant) == ["Spotify"])
        #expect(subject.monthlyTotal == 15)
    }

    /// But they are still listed. Cancelling must not look like deleting.
    @Test func cancelledSubscriptionsAreStillShownSeparately() {
        let subject = state([
            subscription("Spotify", "15.00"),
            subscription("Netflix", "35.00", active: false),
        ])

        #expect(subject.cancelledRows.map(\.subscription.merchant) == ["Netflix"])
    }

    /// Cancelling everything leaves a screen that explains itself rather than an empty one.
    @Test func cancellingEverythingStillShowsEverything() {
        let subject = state([
            subscription("Spotify", "15.00", active: false),
            subscription("Netflix", "35.00", active: false),
        ])

        #expect(subject.monthlyTotal == 0)
        #expect(subject.rows.isEmpty)
        #expect(subject.cancelledRows.count == 2)
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

    /// A statement that ended on the 7th leaves a charge due the 10th in the past by the 13th. It
    /// is still next month's charge, and it sorts as one rather than to the top of the list.
    @Test func aChargeTheStatementNeverSawSortsByWhenItIsActuallyDue() {
        let subject = state(
            [
                subscription("Setanta", "15.00", next: "2026-08-10"),
                subscription("Spotify", "15.00", next: "2026-08-20"),
            ],
            today: day("2026-08-13"))

        var sorted = subject
        _ = sorted.apply(.sortChanged(.nextCharge))

        #expect(sorted.rows.map(\.subscription.merchant) == ["Spotify", "Setanta"])
        #expect(sorted.rows.last?.nextCharge == day("2026-09-10"))
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
        #expect(subject.rows.isEmpty, "nothing loaded, so nothing to show")
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

    @Test func aSwipeAsksAboutTheRowItWasMadeOn() {
        var subject = state([
            subscription("Spotify", "15.00"), subscription("Netflix", "35.00"),
        ])
        let target = subject.all[1]

        #expect(subject.apply(.deleteTapped(target)) == nil, "asked, not done")
        #expect(subject.pendingDelete == target)
        #expect(subject.apply(.deleteConfirmed) == .delete(target.id))
        #expect(subject.pendingDelete == nil)
    }

    /// The row it names, not the row that happens to be first. A swipe lands on whichever one the
    /// thumb was over, which is the whole reason it is worth asking.
    @Test func theAnswerDeletesTheRowThatWasAskedAbout() {
        var subject = state([
            subscription("Spotify", "15.00"), subscription("Netflix", "35.00"),
        ])
        // Read before the answer, not after: confirming removes it from the list there and then.
        let target = subject.all[1]

        _ = subject.apply(.deleteTapped(target))

        #expect(subject.apply(.deleteConfirmed) == .delete(target.id))
    }

    /// The row leaves on the answer rather than when the store gets back, because the write is
    /// asynchronous: waiting for it meant the row outlived the confirmation and then vanished a
    /// moment later, outside whatever animation the tap had begun.
    @Test func confirmingRemovesTheRowBeforeTheStoreIsToldAnything() {
        var subject = state([
            subscription("Spotify", "15.00"), subscription("Netflix", "35.00"),
        ])
        _ = subject.apply(.deleteTapped(subject.all[1]))

        _ = subject.apply(.deleteConfirmed)

        #expect(subject.rows.map(\.subscription.merchant) == ["Spotify"])
    }

    @Test func backingOutOfAsingleDeletionDeletesNothing() {
        var subject = state([subscription("Spotify", "15.00")])

        _ = subject.apply(.deleteTapped(subject.all[0]))

        #expect(subject.apply(.confirmationDismissed) == nil)
        #expect(subject.pendingDelete == nil)
        #expect(subject.apply(.deleteConfirmed) == nil, "nothing is pending to confirm")
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

    @Test func aChangeToTheStoreReloadsRatherThanGuessingTheNewList() {
        var subject = state([subscription("Spotify", "15.00")])

        #expect(subject.apply(.storeChanged) == .load)
    }

    /// The same act as Detail's button, reachable without opening the subscription first.
    @Test func cancellingFromTheListSavesTheFlippedFlag() {
        var subject = state([subscription("Spotify", "15.00")])
        let live = subject.all[0]

        let effect = subject.apply(.activeToggled(live))

        #expect(effect == .save(live.withActive(false)))
    }

    @Test func reactivatingFromTheListSavesItBack() {
        var subject = state([subscription("Netflix", "35.00", active: false)])
        let cancelled = subject.all[0]

        #expect(subject.apply(.activeToggled(cancelled)) == .save(cancelled.withActive(true)))
    }

    /// This screen is only ever shown over data; emptied, it hands the root back to Welcome.
    @Test func emptyingTheStoreReturnsToWelcome() {
        var subject = SubscriptionsState(currency: "GEL")

        #expect(subject.apply(.loaded([], RateBook())) == .exit(.dataCleared))
    }
}

@Suite("Opening the form")
struct SubscriptionsFormTests {
    private func state(_ subscriptions: [Subscription]) -> SubscriptionsState {
        var state = SubscriptionsState(currency: "GEL")
        _ = state.apply(.loaded(subscriptions, rateBook()))
        return state
    }

    @Test func addingOpensABlankForm() {
        var subject = state([subscription("Netflix", "35.00")])

        #expect(subject.apply(.addTapped) == nil)
        #expect(subject.edit?.subscription == nil)
        #expect(subject.edit?.id == "new")
    }

    @Test func editingOpensOnThatSubscription() {
        var subject = state([subscription("Netflix", "35.00")])
        let netflix = subject.all[0]

        #expect(subject.apply(.editTapped(netflix)) == nil)
        #expect(subject.edit?.subscription == netflix)
    }

    /// The form writes to the store itself, so the list only has to catch up with it.
    @Test func savingClosesTheFormAndRereadsTheStore() {
        var subject = state([subscription("Netflix", "35.00")])
        _ = subject.apply(.addTapped)

        #expect(subject.apply(.formFinished(.saved(subscription("Spotify", "15.20")))) == .load)
        #expect(subject.edit == nil)
    }

    @Test func cancellingClosesTheFormAndReadsNothing() {
        var subject = state([subscription("Netflix", "35.00")])
        _ = subject.apply(.addTapped)

        #expect(subject.apply(.formFinished(.cancelled)) == nil)
        #expect(subject.edit == nil)
    }

    @Test func theCurrenciesAlreadyChargedAreOfferedToTheForm() {
        let subject = state([
            subscription("Netflix", "12.99", "USD"), subscription("Spotify", "15.20"),
            subscription("ChatGPT", "20.00", "USD"),
        ])

        #expect(subject.knownCurrencies == ["USD", "GEL"])
    }
}


extension Subscription {
    fileprivate func withActive(_ isActive: Bool) -> Subscription {
        var copy = self
        copy.isActive = isActive
        return copy
    }
}
