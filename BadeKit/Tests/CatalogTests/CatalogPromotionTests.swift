import Catalog
import Core
import Detection
import Foundation
import Testing

/// Spec §7.5 — the accuracy lever: a yearly subscription is detectable from one charge, without
/// waiting two years for a second one.
@Suite("Catalog promotion")
struct CatalogPromotionTests {
    private let detector = SubscriptionDetector(catalog: BundledCatalog())
    private let blind = SubscriptionDetector()

    private func charge(_ merchant: String, _ iso: String, _ amount: String, _ currency: String)
        -> NormalizedTransaction
    {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return NormalizedTransaction(
            raw: RawTransaction(
                date: formatter.date(from: iso)!,
                rawDescription: "SP \(merchant.uppercased())",
                amount: Decimal(string: amount)!,
                currency: currency,
                sourceLine: "\(iso) \(merchant) \(amount)"
            ),
            merchant: merchant,
            merchantConfidence: 1
        )
    }

    @Test func promotesSingleAnnualChargeOnAPricePoint() throws {
        let charges = [charge("Amazon Prime", "2026-02-14", "139.00", "USD")]

        let detected = try #require(detector.detect(charges).first)
        #expect(detected.cadence == .annual)
        #expect(detected.confidence == .confident)
        #expect(detected.occurrences.count == 1)
        #expect(detected.nextChargeDate == charge("x", "2027-02-14", "1", "USD").raw.date)
    }

    @Test func theSameChargeIsInvisibleWithoutTheCatalog() {
        let charges = [charge("Amazon Prime", "2026-02-14", "139.00", "USD")]
        #expect(blind.detect(charges).isEmpty)
    }

    @Test func singleChargeAtAnUnknownPriceIsOnlyUncertain() throws {
        let charges = [charge("Netflix", "2026-02-14", "3.00", "USD")]

        let detected = try #require(detector.detect(charges).first)
        #expect(detected.confidence == .uncertain)
        #expect(detected.cadence == .monthly)
    }

    @Test func singleChargeAtAnUnknownMerchantStaysUndetected() {
        let charges = [charge("Nikora Supermarket", "2026-02-14", "42.10", "GEL")]
        #expect(detector.detect(charges).isEmpty)
    }

    @Test func twoOccurrencesOnAPricePointAreConfidentNotProbable() throws {
        let charges = [
            charge("Spotify", "2026-01-14", "11.99", "USD"),
            charge("Spotify", "2026-02-14", "11.99", "USD"),
        ]

        let detected = try #require(detector.detect(charges).first)
        #expect(detected.confidence == .confident)
    }

    @Test func observedIntervalsOutrankTheCatalog() throws {
        let charges = [
            charge("Amazon Prime", "2026-01-14", "139.00", "USD"),
            charge("Amazon Prime", "2026-02-14", "139.00", "USD"),
            charge("Amazon Prime", "2026-03-14", "139.00", "USD"),
        ]

        let detected = try #require(detector.detect(charges).first)
        #expect(detected.cadence == .monthly)
    }

    @Test func gelSettledForeignChargesFallBackToIntervalDetection() {
        let charges = [charge("Netflix", "2026-02-14", "42.10", "GEL")]
        let detected = detector.detect(charges)

        #expect(detected.first?.confidence == .uncertain)
        #expect(detected.first?.cadence == .monthly)
    }
}
