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
        priceChanges: [PriceChange] = [],
        hasEnded: Bool = false
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
            priceChanges: priceChanges,
            hasEnded: hasEnded)
    }

    /// An ended subscription says so instead of quoting a cadence, which would read as a live cost.
    @Test func anEndedDetectionIsCaptionedByWhenItStopped() {
        let locale = Locale(identifier: "en_US")
        let ended = state([detection("Netflix", confidence: .confident, hasEnded: true)])
            .sections[0].items[0]
        let live = state([detection("Netflix", confidence: .confident)]).sections[0].items[0]
        let month: String = ended.subscription.occurrences.map(\.date).max()!
            .formatted(Date.FormatStyle.dateTime.month(.wide).locale(locale))

        #expect(ended.caption(in: locale) != live.caption(in: locale))
        #expect(
            ended.caption(in: locale)
                == .review.caption(3, .badeLocalized(.review.ended(month), in: locale)))
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

        #expect(subject.decisions == [.included, .excluded, .excluded])
        #expect(subject.selectedCount == 1)
    }

    @Test func nothingUncertainIsEverAddedWithoutAnAnswer() {
        var subject = state([detection("Goodwill", confidence: .uncertain, occurrences: 1)])
        #expect(subject.selectedCount == 0)
        #expect(subject.canConfirm == false)

        #expect(subject.apply(.confirmTapped) == nil)
        #expect(subject.isSaving == false)
    }

    /// Every row answers the same way, whatever tier it is in: an uncertain one is ticked and
    /// unticked exactly like a confident one, and its tier is what says how sure Bade was.
    @Test func anUncertainRowIsTickedLikeAnyOther() {
        var subject = state([detection("Goodwill", confidence: .uncertain)])

        _ = subject.apply(.toggled(0))
        #expect(subject.decisions == [.included])
        #expect(subject.sections.first?.items.first?.decision == .included)

        _ = subject.apply(.toggled(0))
        #expect(subject.decisions == [.excluded])
    }

    /// Nothing leaves the list any more. A row you do not want is simply left unticked, which keeps
    /// what was found on screen instead of making a rejection look like a disappearance.
    @Test func everyDetectionStaysOnScreenHoweverItIsAnswered() {
        let subject = state([
            detection("Netflix", confidence: .confident),
            detection("Goodwill", confidence: .uncertain),
        ])

        #expect(subject.sections.map(\.kind) == [.tier(.confident), .tier(.uncertain)])
    }

    /// Ended rows are all one kind and none are ticked. Mixed with the tiers they inherited both
    /// the checkbox and the two-way card, which put two different questions in one section.
    @Test func nothingEndedArrivesTickedOrAsAQuestion() {
        let subject = state([
            detection("Netflix", confidence: .confident, hasEnded: true),
            detection("Setapp", confidence: .probable, hasEnded: true),
            detection("Goodwill", confidence: .uncertain, hasEnded: true),
        ])

        #expect(subject.sections.map(\.kind) == [.ended])
        #expect(subject.decisions == [.excluded, .excluded, .excluded])
        #expect(subject.selectedCount == 0)
    }

    /// Ticking one is still allowed: unticked is a starting point, not a rule.
    @Test func anEndedRowCanStillBeTickedByHand() {
        var subject = state([detection("Netflix", confidence: .confident, hasEnded: true)])

        _ = subject.apply(.toggled(0))

        #expect(subject.decisions == [.included])
    }

    /// Ended sits apart from the tiers and last, so a stopped charge is never read as live money.
    @Test func endedDetectionsGetTheirOwnSectionAfterTheTiers() {
        let subject = state([
            detection("Netflix", confidence: .confident, hasEnded: true),
            detection("Spotify", confidence: .confident),
            detection("Goodwill", confidence: .uncertain),
        ])

        #expect(subject.sections.map(\.kind) == [.tier(.confident), .tier(.uncertain), .ended])
        #expect(subject.sections.last?.items.map(\.subscription.merchant) == ["Netflix"])
        #expect(subject.sections.first?.items.map(\.subscription.merchant) == ["Spotify"])
    }

    @Test func sectionsRunMostCertainFirstAndDropEmptyTiers() {
        let subject = state([
            detection("Goodwill", confidence: .uncertain),
            detection("Netflix", confidence: .confident),
        ])

        #expect(subject.sections.map(\.kind) == [.tier(.confident), .tier(.uncertain)])
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
        #expect(
            subject.apply(.saved(addedCount: 1)) == .exit(.saved(addedCount: 1)))
    }

    /// Nothing new means the statement had been imported before, and the root says so rather than
    /// leaving the silence to be read as failure.
    @Test func savingNothingNewIsReportedAsSuch() {
        var subject = state([detection("Netflix", confidence: .confident)])

        #expect(subject.apply(.saved(addedCount: 0)) == .exit(.saved(addedCount: 0)))
        #expect(!subject.isSaving)
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

    /// The header counts what is ticked and nothing else, so it agrees with the button beneath it
    /// and with the total the home screen shows a moment later.
    @Test func theTotalCountsOnlyWhatIsTicked() {
        var subject = state([
            detection("Netflix", confidence: .confident, amount: 35),
            detection("Goodwill", confidence: .uncertain, amount: 25),
        ])
        #expect(subject.monthlyTotal == 35)

        _ = subject.apply(.toggled(1))

        #expect(subject.monthlyTotal == 60)
        #expect(subject.selectedCount == 2)
    }

    @Test func untickingARowTakesItsMoneyBackOut() {
        var subject = state([detection("Netflix", confidence: .confident, amount: 35)])

        _ = subject.apply(.toggled(0))

        #expect(subject.monthlyTotal == 0)
        #expect(subject.selectedCount == 0)
    }

    /// Ticking something that already stopped keeps it as a record, not as spend: the count moves
    /// and the money does not.
    @Test func anEndedRowAddsToTheCountButNotTheTotal() {
        var subject = state([
            detection("Netflix", confidence: .confident, amount: 35),
            detection("Setapp", confidence: .confident, amount: 25, hasEnded: true),
        ])
        #expect(subject.monthlyTotal == 35)

        _ = subject.apply(.toggled(1))

        #expect(subject.selectedCount == 2)
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
