import Core
import Foundation
import Testing

@testable import Detection

private let detector = SubscriptionDetector()

@Suite("Cadence clustering")
struct CadenceDetectionTests {
    @Test(arguments: [
        (Cadence.weekly, 7), (.monthly, 30), (.quarterly, 91), (.semiannual, 182), (.annual, 365),
    ])
    func detectsEachCadence(cadence: Cadence, spacing: Int) {
        let dates = (0..<4).map { Date(timeIntervalSince1970: TimeInterval($0 * spacing * 86400)) }
        let charges = dates.map {
            NormalizedTransaction(
                raw: RawTransaction(
                    date: $0, rawDescription: "SP ACME", amount: 10, currency: "GEL",
                    sourceLine: "x"),
                merchant: "Acme", merchantConfidence: 1)
        }

        let detected = detector.detect(charges)
        #expect(detected.count == 1)
        #expect(detected.first?.cadence == cadence)
    }

    @Test func rejectsIntervalsBetweenCadenceWindows() {
        let charges = [
            charge("Acme", "2026-01-05", "10"),
            charge("Acme", "2026-02-19", "10"),
            charge("Acme", "2026-04-05", "10"),
        ]
        #expect(detector.detect(charges).isEmpty)
    }

    @Test func ignoresSingleCharges() {
        #expect(detector.detect([charge("Acme", "2026-01-05", "10")]).isEmpty)
    }

    @Test func detectsNothingInEmptyInput() {
        #expect(detector.detect([]).isEmpty)
    }
}

@Suite("Confidence")
struct ConfidenceTests {
    @Test func threeOccurrencesAreConfident() {
        let detected = detector.detect(monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "35.99"))
        #expect(detected.first?.confidence == .confident)
    }

    @Test func twoOccurrencesAreProbable() {
        let detected = detector.detect(monthlyCharges("Netflix", from: "2026-01-09", count: 2, amount: "35.99"))
        #expect(detected.first?.confidence == .probable)
    }
}

@Suite("Grouping")
struct GroupingTests {
    @Test func groupsAcrossFXDriftWithinTolerance() {
        let charges = [
            charge("Spotify", "2026-01-14", "35.99"),
            charge("Spotify", "2026-02-14", "37.50"),
            charge("Spotify", "2026-03-14", "34.80"),
        ]

        let detected = detector.detect(charges)
        #expect(detected.count == 1)
        #expect(detected.first?.occurrences.count == 3)
        #expect(detected.first?.isVariableAmount == false)
    }

    @Test func separatesConcurrentSubscriptionsFromOneMerchant() {
        let charges =
            monthlyCharges("Apple", from: "2026-01-05", count: 3, amount: "2.99")
            + monthlyCharges("Apple", from: "2026-01-20", count: 3, amount: "29.99")

        let detected = detector.detect(charges)
        #expect(detected.count == 2)
        #expect(detected.map(\.amount).sorted() == [Decimal(string: "2.99")!, Decimal(string: "29.99")!])
    }

    @Test func separatesSameAmountAcrossCurrencies() {
        let charges =
            monthlyCharges("Acme", from: "2026-01-05", count: 3, amount: "10.00")
            + monthlyCharges("Acme", from: "2026-01-05", count: 3, amount: "10.00", currency: "USD")

        let detected = detector.detect(charges)
        #expect(detected.count == 2)
        #expect(detected.map(\.currency) == ["GEL", "USD"])
    }

    @Test func ignoresIrregularOneOffPurchases() {
        let charges = [
            charge("Amazon", "2026-01-03", "12.40"),
            charge("Amazon", "2026-01-19", "88.00"),
            charge("Amazon", "2026-03-02", "5.10"),
        ]
        #expect(detector.detect(charges).isEmpty)
    }

    @Test func ordersResultsDeterministically() {
        let charges =
            monthlyCharges("Spotify", from: "2026-01-14", count: 3, amount: "24.99")
            + monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "35.99")

        #expect(detector.detect(charges).map(\.merchant) == ["Netflix", "Spotify"])
    }
}

@Suite("Hard cases from spec §7")
struct HardCaseTests {
    @Test func dedupesOverlappingStatementImports() {
        let charges = monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "35.99")

        let detected = detector.detect(charges + charges)
        #expect(detected.count == 1)
        #expect(detected.first?.occurrences.count == 3)
    }

    @Test func keepsSameDayChargesThatDifferInDescription() {
        let charges = [
            charge("Acme", "2026-01-05", "10", rawDescription: "SP ACME REF001"),
            charge("Acme", "2026-01-05", "10", rawDescription: "SP ACME REF002"),
        ]

        let deduped = TransactionDeduplicator().deduplicate(charges)
        #expect(deduped.count == 2)
    }

    @Test func flagsVariableAmountsAndStillDetectsCadence() throws {
        let charges = [
            charge("City Water", "2026-01-11", "40.10"),
            charge("City Water", "2026-02-11", "52.60"),
            charge("City Water", "2026-03-11", "38.20"),
        ]

        let detected = try #require(detector.detect(charges).first)
        #expect(detected.cadence == .monthly)
        #expect(detected.isVariableAmount)
        #expect(detected.amount == Decimal(string: "38.20")!)
        #expect(detected.priceChanges.isEmpty)
    }

    @Test func recordsPriceChangeWithoutSplittingTheSubscription() throws {
        let charges =
            monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "29.99")
            + monthlyCharges("Netflix", from: "2026-04-09", count: 3, amount: "35.99")

        let all = detector.detect(charges)
        let detected = try #require(all.first)
        #expect(all.count == 1)
        #expect(detected.occurrences.count == 6)
        #expect(!detected.isVariableAmount)
        #expect(detected.amount == Decimal(string: "35.99")!)
        #expect(detected.priceChanges.count == 1)
        #expect(detected.priceChanges.first?.from == Decimal(string: "29.99")!)
        #expect(detected.priceChanges.first?.to == Decimal(string: "35.99")!)
        #expect(detected.priceChanges.first?.date == day("2026-04-09"))
    }

    @Test func treatsTrialConversionAsOneSubscription() throws {
        let charges =
            [charge("Netflix", "2026-01-09", "0")]
            + monthlyCharges("Netflix", from: "2026-02-09", count: 3, amount: "35.00")

        let all = detector.detect(charges)
        let detected = try #require(all.first)
        #expect(all.count == 1)
        #expect(detected.occurrences.count == 4)
        #expect(!detected.isVariableAmount)
        #expect(detected.priceChanges.count == 1)
        #expect(detected.priceChanges.first?.from == 0)
        #expect(detected.priceChanges.first?.to == Decimal(string: "35.00")!)
    }

    @Test func keepsCancelledThenResumedAsOneSubscription() throws {
        let charges =
            monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "35.99")
            + monthlyCharges("Netflix", from: "2026-09-09", count: 3, amount: "35.99")

        let all = detector.detect(charges)
        let detected = try #require(all.first)
        #expect(all.count == 1)
        #expect(detected.cadence == .monthly)
        #expect(detected.occurrences.count == 6)
        #expect(detected.nextChargeDate == day("2026-12-09"))
    }

    @Test(.disabled("needs Catalog merchant aliases — build step 4"))
    func linksMerchantRenameMidHistory() throws {
        let charges =
            monthlyCharges("FB Pay", from: "2026-01-09", count: 3, amount: "15.00")
            + monthlyCharges("Meta", from: "2026-04-09", count: 3, amount: "15.00")

        let all = detector.detect(charges)
        let detected = try #require(all.first)
        #expect(all.count == 1)
        #expect(detected.merchant == "Meta")
        #expect(detected.occurrences.count == 6)
    }
}

@Suite("Next charge date")
struct NextChargeTests {
    @Test func projectsOneIntervalPastTheLastCharge() {
        let detected = detector.detect(monthlyCharges("Netflix", from: "2026-01-09", count: 3, amount: "35.99"))
        #expect(detected.first?.nextChargeDate == day("2026-04-09"))
    }

    @Test func clampsMonthEndRatherThanOverflowing() {
        let charges = [
            charge("Acme", "2025-11-30", "10"),
            charge("Acme", "2025-12-30", "10"),
            charge("Acme", "2026-01-30", "10"),
        ]
        #expect(detector.detect(charges).first?.nextChargeDate == day("2026-02-28"))
    }
}
