import Core
import Foundation
import Testing

@testable import Detection

@Suite("Repeat candidates")
struct RepeatCandidateTests {
    private let detector = SubscriptionDetector()

    @Test func offersAMerchantChargedRepeatedlyWithNoRhythm() {
        let charges = [
            charge("Corner Shop", "2026-01-04", "12.00"),
            charge("Corner Shop", "2026-01-19", "31.50"),
            charge("Corner Shop", "2026-03-02", "8.25"),
        ]

        let outcome = detector.analyse(charges)
        #expect(outcome.subscriptions.isEmpty)
        #expect(outcome.candidates.map(\.merchant) == ["Corner Shop"])
        #expect(outcome.candidates[0].occurrences.count == 3)
    }

    /// The amount a form would open with is the most recent one, not the first or the largest.
    @Test func carriesTheLatestAmountForward() throws {
        let charges = [
            charge("Corner Shop", "2026-01-04", "40.00"),
            charge("Corner Shop", "2026-01-19", "31.50"),
            charge("Corner Shop", "2026-03-02", "8.25"),
        ]

        let candidate = try #require(detector.analyse(charges).candidates.first)
        #expect(candidate.amount == Decimal(string: "8.25")!)
        #expect(candidate.lastChargeDate == charge("x", "2026-03-02", "1").raw.date)
    }

    @Test func twiceIsNotEnoughToAskAbout() {
        let charges = [
            charge("Corner Shop", "2026-01-04", "12.00"),
            charge("Corner Shop", "2026-02-19", "31.50"),
        ]

        #expect(detector.analyse(charges).candidates.isEmpty)
    }

    /// A merchant already reported needs no second answer about the same charges.
    @Test func aMerchantThatBecameASubscriptionIsNotAlsoAskedAbout() {
        let charges = monthlyCharges("Netflix", from: "2026-01-09", count: 4, amount: "35.99")

        let outcome = detector.analyse(charges)
        #expect(outcome.subscriptions.map(\.merchant) == ["Netflix"])
        #expect(outcome.candidates.isEmpty)
    }

    /// Everyday categories are excluded before the question is asked, or the list is all groceries.
    @Test func neverAsksAboutCategoriesThatCannotRecur() {
        let charges = ["2026-01-04", "2026-01-23", "2026-03-08"].map {
            charge("Corner Shop", $0, "12.00", mcc: MerchantCategory.neverRecurring.first!)
        }

        #expect(detector.analyse(charges).candidates.isEmpty)
    }

    @Test func oneCandidatePerMerchantAndCurrency() {
        let irregular = ["2026-01-04", "2026-01-23", "2026-03-08"]
        let charges =
            irregular.map { charge("Shop", $0, "12.00", currency: "GEL") }
            + irregular.map { charge("Shop", $0, "9.00", currency: "USD") }

        let candidates = detector.analyse(charges).candidates
        #expect(candidates.count == 2)
        #expect(Set(candidates.map(\.currency)) == ["GEL", "USD"])
        #expect(Set(candidates.map(\.id)).count == 2)
    }

    @Test func detectStillAnswersWithJustTheSubscriptions() {
        let charges =
            monthlyCharges("Netflix", from: "2026-01-09", count: 4, amount: "35.99")
            + ["2026-01-04", "2026-01-23", "2026-03-08"].map {
                charge("Corner Shop", $0, "12.00")
            }

        #expect(detector.detect(charges) == detector.analyse(charges).subscriptions)
        #expect(detector.analyse(charges).candidates.count == 1)
    }
}
