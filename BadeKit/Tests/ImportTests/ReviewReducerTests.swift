import Core
import Foundation
import Testing

@testable import Import

@Suite("Review state")
struct ReviewStateTests {
    private func detection(
        _ merchant: String,
        confidence: Confidence,
        amount: Decimal = 10,
        currency: String = "GEL",
        occurrences: Int = 3,
        priceChanges: [PriceChange] = []
    ) -> DetectedSubscription {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        return DetectedSubscription(
            merchant: merchant,
            amount: amount,
            currency: currency,
            cadence: .monthly,
            occurrences: (0..<occurrences).map {
                RawTransaction(
                    date: start.addingTimeInterval(Double($0) * 2_592_000),
                    rawDescription: merchant, amount: amount, currency: currency,
                    sourceLine: merchant)
            },
            nextChargeDate: start,
            confidence: confidence,
            priceChanges: priceChanges)
    }

    private func state(_ detected: [DetectedSubscription], rates: RateBook = RateBook())
        -> ReviewState
    {
        ReviewState(detected: detected, rates: rates, currency: "GEL")
    }

    @Test func confidenceDecidesWhatArrivesTicked() {
        let subject = state([
            detection("Netflix", confidence: .confident),
            detection("Setapp", confidence: .probable),
            detection("Goodwill", confidence: .uncertain),
        ])

        #expect(subject.decisions == [.included, .excluded, .undecided])
        #expect(subject.selectedCount == 1)
    }

    @Test func nothingUncertainIsEverAddedWithoutAnAnswer() {
        var subject = state([detection("Goodwill", confidence: .uncertain, occurrences: 1)])
        #expect(subject.selectedCount == 0)
        #expect(subject.canConfirm == false)

        #expect(subject.apply(.confirmTapped) == nil)
        #expect(subject.isSaving == false)
    }

    @Test func answeringUncertainTurnsItIntoAnOrdinaryRow() {
        var subject = state([detection("Goodwill", confidence: .uncertain)])

        _ = subject.apply(.acceptedUncertain(0))
        #expect(subject.decisions == [.included])
        #expect(subject.sections.first?.items.first?.decision == .included)

        _ = subject.apply(.toggled(0))
        #expect(subject.decisions == [.excluded])
    }

    @Test func notOneRemovesItFromTheListAndTheSummary() {
        var subject = state([
            detection("Netflix", confidence: .confident),
            detection("Goodwill", confidence: .uncertain),
        ])
        #expect(subject.remainingCount == 2)

        _ = subject.apply(.rejectedUncertain(1))

        #expect(subject.remainingCount == 1)
        #expect(subject.sections.map(\.confidence) == [.confident])
    }

    @Test func sectionsRunMostCertainFirstAndDropEmptyTiers() {
        let subject = state([
            detection("Goodwill", confidence: .uncertain),
            detection("Netflix", confidence: .confident),
        ])

        #expect(subject.sections.map(\.confidence) == [.confident, .uncertain])
    }

    @Test func togglingIsReversible() {
        var subject = state([detection("Netflix", confidence: .confident)])

        _ = subject.apply(.toggled(0))
        #expect(subject.selectedCount == 0)
        _ = subject.apply(.toggled(0))
        #expect(subject.selectedCount == 1)
    }

    @Test func confirmSavesOnlyWhatIsTicked() {
        var subject = state([
            detection("Netflix", confidence: .confident),
            detection("Setapp", confidence: .probable),
        ])

        let effect = subject.apply(.confirmTapped)

        #expect(effect == .save([subject.detected[0]]))
        #expect(subject.isSaving)
    }

    @Test func aFailedSaveKeepsTheUserOnTheScreen() {
        var subject = state([detection("Netflix", confidence: .confident)])
        _ = subject.apply(.confirmTapped)

        let effect = subject.apply(.saveFailed)

        #expect(effect == nil)
        #expect(subject.didFailToSave)
        #expect(subject.isSaving == false)
        #expect(subject.canConfirm, "the user must be able to try again")
    }

    @Test func retryingClearsTheFailure() {
        var subject = state([detection("Netflix", confidence: .confident)])
        _ = subject.apply(.confirmTapped)
        _ = subject.apply(.saveFailed)

        _ = subject.apply(.confirmTapped)

        #expect(subject.didFailToSave == false)
    }

    @Test func leavingIsAnIntentLikeAnythingElse() {
        var subject = state([detection("Netflix", confidence: .confident)])

        #expect(subject.apply(.closeTapped) == .exit(.cancelled))
        #expect(subject.apply(.saved) == .exit(.saved))
    }

    @Test func theTotalUsesTheRateTheBankActuallyCharged() {
        var rates = RateBook()
        rates.record(
            ObservedRate(
                date: Date(timeIntervalSince1970: 1_700_000_000), from: "USD", to: "GEL",
                rate: 2.72))
        let subject = state(
            [
                detection("ChatGPT", confidence: .confident, amount: 20, currency: "USD"),
                detection("YouTube", confidence: .confident, amount: 42.90),
            ], rates: rates)

        #expect(subject.monthlyTotal == Decimal(string: "97.30")!)
    }

    @Test func aDismissedRowLeavesTheTotal() {
        var subject = state([
            detection("Netflix", confidence: .confident, amount: 35),
            detection("Goodwill", confidence: .uncertain, amount: 25),
        ])
        #expect(subject.monthlyTotal == 60)

        _ = subject.apply(.rejectedUncertain(1))

        #expect(subject.monthlyTotal == 35)
    }

    @Test func aForeignChargeShowsBothWhatWasBilledAndWhatWasCharged() {
        var rates = RateBook()
        rates.record(
            ObservedRate(
                date: Date(timeIntervalSince1970: 1_700_000_000), from: "USD", to: "GEL",
                rate: 2.72))
        let subject = state(
            [detection("ChatGPT", confidence: .confident, amount: 20, currency: "USD")],
            rates: rates)
        let item = subject.sections[0].items[0]

        #expect(item.displayAmount(in: "GEL") == Decimal(string: "54.40")!)
        #expect(item.displayCurrency("GEL") == "GEL")
        #expect(item.originalAmount(displayedIn: "GEL") == 20)
    }

    @Test func aChargeWithNoRateIsShownInItsOwnCurrencyRatherThanGuessed() {
        let subject = state(
            [detection("ChatGPT", confidence: .confident, amount: 20, currency: "USD")])
        let item = subject.sections[0].items[0]

        #expect(item.displayAmount(in: "GEL") == 20)
        #expect(item.displayCurrency("GEL") == "USD")
        #expect(item.originalAmount(displayedIn: "GEL") == nil)
    }
}
