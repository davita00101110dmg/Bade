import Catalog
import Core
import Detection
import Foundation
import Ingestion
import Normalization
import Testing

/// Wires the modules the way `App` will: parse, normalise, detect. No Foundation Models
/// anywhere in this path — §14.2 requires the app to work with Apple Intelligence unavailable.
private struct Pipeline {
    private let parser = BOGStatementParser()
    private let normalizer: MerchantNormalizer
    private let detector: SubscriptionDetector

    init() {
        let catalog = BundledCatalog()
        normalizer = MerchantNormalizer(directory: catalog)
        detector = SubscriptionDetector(catalog: catalog)
    }

    func subscriptions(from statement: String) throws -> [DetectedSubscription] {
        detector.detect(normalizer.normalize(try parser.parse(statement)))
    }
}

@Suite("End-to-end, no LLM")
struct EndToEndTests {
    private let pipeline = Pipeline()

    private func record(_ amount: String, _ merchant: String, _ date: String) -> String {
        "Payment - Amount: GEL\(amount); Merchant: \(merchant); MCC:4899; Date: \(date) 00:00; "
    }

    /// The exact failure real data exposed: one subscription behind three merchant strings.
    @Test func collapsesPerChargeReferencesIntoOneSubscription() throws {
        let statement =
            record("15.48", "PAYPAL *SPOTIFY*P42A20, United Kingdom", "20/05/2026")
            + record("15.35", "PAYPAL *SPOTIFY*P43B78, United Kingdom", "20/06/2026")
            + record("15.20", "PAYPAL *SPOTIFY*P44C5B, United Kingdom", "20/07/2026")

        let detected = try pipeline.subscriptions(from: statement)
        #expect(detected.count == 1)
        #expect(detected.first?.merchant == "Spotify")
        #expect(detected.first?.cadence == .monthly)
        #expect(detected.first?.occurrences.count == 3)
        #expect(detected.first?.confidence == .confident)
    }

    @Test func recordsAPriceRiseAsOneSubscription() throws {
        let statement =
            record("10.29", "GOOGLE *YouTubePremium, United States of America", "27/05/2026")
            + record("17.49", "GOOGLE *YouTubePremium, United States of America", "27/06/2026")
            + record("17.49", "GOOGLE *YouTubePremium, United States of America", "28/07/2026")

        let detected = try pipeline.subscriptions(from: statement)
        #expect(detected.count == 1)
        #expect(detected.first?.merchant == "YouTube Premium")
        #expect(detected.first?.amount == Decimal(string: "17.49")!)
        #expect(detected.first?.priceChanges.count == 1)
        #expect(detected.first?.priceChanges.first?.from == Decimal(string: "10.29")!)
        #expect(detected.first?.priceChanges.first?.to == Decimal(string: "17.49")!)
    }

    @Test func ignoresIrregularEverydaySpending() throws {
        let statement =
            record("29.43", "Wolt, Tbilisi, 61 Agmashenebeli ave.", "07/05/2026")
            + record("20.31", "Wolt, Tbilisi, 61 Agmashenebeli ave.", "09/05/2026")
            + record("32.13", "Wolt, Tbilisi, 61 Agmashenebeli ave.", "11/05/2026")

        #expect(try pipeline.subscriptions(from: statement).isEmpty)
    }

    @Test func separatesTwoSubscriptionsFromOneStatement() throws {
        let statement =
            record("8.99", "Epidemic Sound, Sweden", "21/05/2026")
            + record("8.99", "Epidemic Sound, Sweden", "21/06/2026")
            + record("8.99", "Epidemic Sound, Sweden", "21/07/2026")
            + record("19.99", "AMZ*Adobe, United States of America", "19/05/2026")
            + record("19.99", "AMZ*Adobe, United States of America", "19/06/2026")
            + record("19.99", "AMZ*Adobe, United States of America", "19/07/2026")

        let detected = try pipeline.subscriptions(from: statement)
        #expect(detected.count == 2)
        #expect(detected.map(\.merchant) == ["Adobe Creative Cloud", "Epidemic Sound"])
        #expect(detected.allSatisfy { $0.cadence == .monthly })
    }

    @Test func worksIdenticallyOnGeorgianStatements() throws {
        let georgian = (1...3).map { month in
            "გადახდა - თანხა: GEL8.99; ობიექტი: Epidemic Sound, Sweden; MCC:5815; "
                + "თარიღი: 21/0\(month + 4)/2026 00:00; "
        }.joined()

        let detected = try pipeline.subscriptions(from: georgian)
        #expect(detected.count == 1)
        #expect(detected.first?.merchant == "Epidemic Sound")
        #expect(detected.first?.cadence == .monthly)
    }
}
