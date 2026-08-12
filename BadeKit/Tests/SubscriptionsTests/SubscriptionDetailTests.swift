import Core
import Foundation
import Testing

@testable import Subscriptions

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

private func charge(_ iso: String, _ amount: String, _ currency: String = "GEL") -> Charge {
    Charge(date: day(iso), amount: Decimal(string: amount)!, currency: currency, conversion: nil)
}

private func subscription(
    charges: [Charge], currency: String = "GEL", amount: String = "10.00",
    priceChanges: [PriceChange] = [], active: Bool = true
) -> Subscription {
    Subscription(
        merchant: "Netflix", amount: Decimal(string: amount)!, currency: currency,
        cadence: .monthly, firstChargeDate: charges.map(\.date).min() ?? day("2026-01-01"),
        lastChargeDate: charges.map(\.date).max() ?? day("2026-08-01"),
        nextChargeDate: day("2026-09-01"), charges: charges, priceChanges: priceChanges,
        isActive: active, confidence: .confident)
}

private func rateBook() -> RateBook {
    var book = RateBook()
    book.record(ObservedRate(date: day("2026-08-01"), from: "USD", to: "GEL", rate: 2.72))
    return book
}

@Suite("Subscription detail")
struct SubscriptionDetailTests {
    private func state(_ subscription: Subscription, rates: RateBook = rateBook())
        -> SubscriptionDetailState
    {
        SubscriptionDetailState(subscription: subscription, currency: "GEL", rates: rates)
    }

    @Test func historyIsTwelveMonthsEndingOnTheLastCharge() {
        let subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))

        #expect(subject.history.count == 12)
        #expect(subject.history.last?.month == day("2026-08-01"))
        #expect(subject.history.first?.month == day("2025-09-01"))
    }

    /// A subscription that stopped still shows the history it had, not a year of blanks.
    @Test func aStoppedSubscriptionKeepsItsShape() {
        let subject = state(
            subscription(charges: [charge("2026-02-01", "10.00"), charge("2026-03-01", "10.00")]))

        #expect(subject.history.last?.month == day("2026-03-01"))
        #expect(subject.history.filter { !$0.isEmpty }.count == 2)
    }

    @Test func monthsWithNoChargeAreEmptyRatherThanMissing() {
        let subject = state(
            subscription(charges: [charge("2026-06-01", "10.00"), charge("2026-08-01", "10.00")]))

        let july = subject.history.first { $0.month == day("2026-07-01") }
        #expect(july?.isEmpty == true)
        #expect(july?.fraction == 0)
    }

    @Test func theTallestMonthFillsTheChart() {
        let subject = state(
            subscription(charges: [charge("2026-07-01", "5.00"), charge("2026-08-01", "10.00")]))

        let bars = subject.history.filter { !$0.isEmpty }
        #expect(bars.last?.fraction == 1)
        #expect(bars.first?.fraction == 0.5)
    }

    @Test func twoChargesInOneMonthAddUp() {
        let subject = state(
            subscription(charges: [charge("2026-08-03", "4.00"), charge("2026-08-20", "6.00")]))

        #expect(subject.history.last?.amount == 10)
    }

    @Test func theMonthAPriceRoseIsMarked() {
        let change = PriceChange(
            date: day("2026-07-01"), from: Decimal(string: "8.00")!, to: Decimal(string: "10.00")!)
        let subject = state(
            subscription(
                charges: [charge("2026-07-01", "10.00"), charge("2026-08-01", "10.00")],
                priceChanges: [change]))

        #expect(subject.history.first { $0.month == day("2026-07-01") }?.isPriceRise == true)
        #expect(subject.history.first { $0.month == day("2026-08-01") }?.isPriceRise == false)
    }

    /// A rise and a fall are not the same news, so only one of them is coloured as bad.
    @Test func aPriceFallIsNotMarkedAsARise() {
        let change = PriceChange(
            date: day("2026-07-01"), from: Decimal(string: "10.00")!, to: Decimal(string: "8.00")!)
        let subject = state(
            subscription(charges: [charge("2026-07-01", "8.00")], priceChanges: [change]))

        let july = subject.history.first { $0.month == day("2026-07-01") }
        #expect(july?.priceChange != nil)
        #expect(july?.isPriceRise == false)
    }

    @Test func aForeignChargeIsChartedInTheDisplayCurrency() {
        let subject = state(
            subscription(charges: [charge("2026-08-01", "10.00", "USD")], currency: "USD"))

        #expect(subject.displayCurrency == "GEL")
        #expect(subject.history.last?.amount == Decimal(string: "27.20")!)
    }

    /// Without a rate the detail shows the charge as billed rather than inventing a conversion.
    @Test func anUnconvertibleChargeStaysInItsOwnCurrency() {
        let subject = state(
            subscription(charges: [charge("2026-08-01", "9.00", "EUR")], currency: "EUR"),
            rates: RateBook())

        #expect(subject.displayCurrency == "EUR")
        #expect(subject.showsBilledPrice == false)
        #expect(subject.history.last?.amount == 9)
    }

    @Test func aManualSubscriptionHasNoHistoryToDraw() {
        let subject = state(subscription(charges: []))

        #expect(subject.hasHistory == false)
        #expect(subject.history.allSatisfy { $0.isEmpty })
    }

    @Test func cancellingIsReversibleAndSaves() {
        var subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))

        let effect = subject.apply(.activeToggled)
        var expected = subject.subscription
        expected.isActive = false
        #expect(effect == .save(expected))
    }

    @Test func deletingAsksFirst() {
        var subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))

        #expect(subject.apply(.deleteRequested) == nil)
        #expect(subject.isConfirmingDelete)
        #expect(subject.apply(.deleteConfirmed) == .delete(subject.subscription.id))
    }

    @Test func dismissingDeletesNothing() {
        var subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))
        _ = subject.apply(.deleteRequested)

        #expect(subject.apply(.confirmationDismissed) == nil)
        #expect(subject.isConfirmingDelete == false)
    }

    @Test func editingOpensTheFormAndSavingShowsWhatItWrote() {
        var subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))
        var amended = subject.subscription
        amended.merchant = "Netflix Family"

        #expect(subject.apply(.editTapped) == nil)
        #expect(subject.isEditing)
        #expect(subject.apply(.formFinished(.saved(amended))) == .exit(.changed))
        #expect(subject.isEditing == false)
        #expect(subject.subscription.merchant == "Netflix Family")
    }

    @Test func leavingTheFormAloneChangesNothingBehindIt() {
        var subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))
        _ = subject.apply(.editTapped)

        #expect(subject.apply(.formFinished(.cancelled)) == nil)
        #expect(subject.isEditing == false)
        #expect(subject.subscription.merchant == "Netflix")
    }

    @Test func anythingThatChangedMakesTheListBehindItStale() {
        var subject = state(subscription(charges: [charge("2026-08-01", "10.00")]))

        #expect(subject.apply(.saved(subject.subscription)) == .exit(.changed))
        #expect(subject.apply(.deletionFinished) == .exit(.deleted))
    }
}
