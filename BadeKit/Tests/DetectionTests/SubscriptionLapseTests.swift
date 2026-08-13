import Core
import Foundation
import Testing

@testable import Detection

/// A statement's other transactions are what tell us the statement kept running. Without one of
/// these, the last subscription charge is also the end of the evidence and nothing has lapsed.
private func statementRunsUntil(_ iso: String) -> [NormalizedTransaction] {
    [charge("Corner Shop", iso, "4.20", rawDescription: "SP CORNER SHOP REF999")]
}

@Suite("Lapsed subscriptions")
struct SubscriptionLapseTests {
    private let detector = SubscriptionDetector()

    /// Fourteen months of Netflix, then six months of silence before the statement ends. Reported,
    /// and marked ended: a subscription somebody plainly paid for is worth seeing, and hiding it
    /// left them unable to check that it really did stop.
    @Test func aSubscriptionThatStoppedMonthsAgoIsReportedAsEnded() {
        let charges =
            monthlyCharges("Netflix", from: "2025-01-09", count: 14, amount: "35.99")
            + statementRunsUntil("2026-08-30")

        let detected = detector.detect(charges)
        #expect(detected.count == 1)
        #expect(detected.first?.hasEnded == true)
    }

    @Test func theLastChargeStillCountsWhileTheCycleIsOpen() {
        let charges =
            monthlyCharges("Netflix", from: "2026-01-09", count: 6, amount: "35.99")
            + statementRunsUntil("2026-06-28")

        #expect(detector.detect(charges).map(\.hasEnded) == [false])
    }

    /// A charge that posts late must not read as a cancellation — half a cycle of slack.
    @Test func aLateChargeIsNotACancellation() {
        let charges =
            monthlyCharges("Netflix", from: "2026-01-09", count: 6, amount: "35.99")
            + statementRunsUntil("2026-07-20")

        #expect(detector.detect(charges).map(\.hasEnded) == [false])
    }

    /// The trap a flat "no charge in the last month or two" rule falls into.
    @Test func anAnnualSubscriptionSurvivesElevenSilentMonths() {
        let charges = [
            charge("Setapp", "2024-09-01", "120"),
            charge("Setapp", "2025-09-01", "120"),
        ] + statementRunsUntil("2026-08-01")

        let detected = detector.detect(charges)
        #expect(detected.count == 1)
        #expect(detected.first?.cadence == .annual)
        #expect(detected.first?.hasEnded == false)
    }

    @Test func anAnnualSubscriptionTwoYearsSilentHasEnded() {
        let charges = [
            charge("Setapp", "2023-09-01", "120"),
            charge("Setapp", "2024-09-01", "120"),
        ] + statementRunsUntil("2026-08-01")

        #expect(detector.detect(charges).map(\.hasEnded) == [true])
    }

    /// Judged against the statement, never against today — an old statement is not a cancellation.
    @Test func anOldStatementStillReportsWhatWasLiveWhenItEnded() {
        let charges = monthlyCharges("Netflix", from: "2019-01-09", count: 6, amount: "35.99")

        #expect(detector.detect(charges).count == 1)
    }

    /// One ending does not mark the others: the judgement is per subscription, against the same
    /// statement end.
    @Test func onlyTheLapsedOneIsMarkedEnded() {
        let charges =
            monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "35.99")
            + monthlyCharges("Spotify", from: "2026-01-20", count: 8, amount: "15.20")

        let detected = detector.detect(charges)
        #expect(detected.map(\.merchant) == ["Netflix", "Spotify"])
        #expect(detected.map(\.hasEnded) == [true, false])
    }

    /// Confirming an ended detection stores it cancelled, which is what keeps it out of the
    /// monthly total, out of Upcoming and out of the widget.
    @Test func anEndedDetectionBecomesACancelledSubscription() {
        let charges =
            monthlyCharges("Netflix", from: "2025-01-09", count: 14, amount: "35.99")
            + statementRunsUntil("2026-08-30")

        let detected = try! #require(detector.detect(charges).first)
        #expect(Subscription(confirming: detected).isActive == false)
    }
}
