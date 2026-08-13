import Catalog
import Core
import Detection
import Foundation
import Ingestion
import Normalization
import Testing

/// Runs the whole pipeline over a real statement. Skips wherever the fixture is absent,
/// which is everywhere except the author's machine — statements are never committed.
enum LocalPipeline {
    static let fixture = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures/local/bog-statement-full-en.txt")

    static var text: String? { try? String(contentsOf: fixture, encoding: .utf8) }
    static var isAvailable: Bool { text != nil }

    static func subscriptions() throws -> [DetectedSubscription] {
        let catalog = BundledCatalog()
        let raw = try BOGStatementParser().parse(text!)
        return SubscriptionDetector(catalog: catalog)
            .detect(MerchantNormalizer(directory: catalog).normalize(raw))
    }
}

@Suite("Real statement pipeline", .enabled(if: LocalPipeline.isAvailable))
struct RealStatementPipelineTests {
    @Test(arguments: [
        ("Spotify", "15.20"), ("Adobe Creative Cloud", "19.99"), ("Epidemic Sound", "8.99"),
        ("Setanta Sports", "14.99"), ("Magti", "35"),
    ])
    func findsKnownMonthlySubscriptions(merchant: String, amount: String) throws {
        let match = try #require(LocalPipeline.subscriptions().first { $0.merchant == merchant })
        #expect(match.cadence == .monthly)
        #expect(match.confidence == .confident)
        #expect(match.occurrences.count >= 3)
        #expect(match.amount == Decimal(string: amount)!)
    }

    /// Three PayPal reference strings, one subscription — the failure real data exposed.
    @Test func collapsesSpotifyReferenceStrings() throws {
        let spotify = try LocalPipeline.subscriptions().filter { $0.merchant == "Spotify" }
        #expect(spotify.count == 1)
        #expect(spotify.first?.occurrences.count == 3)
    }

    @Test func recoversTheYouTubePriceRise() throws {
        let youtube = try #require(
            LocalPipeline.subscriptions().first { $0.merchant == "YouTube Premium" })
        #expect(youtube.amount == Decimal(string: "17.49")!)
        #expect(youtube.priceChanges.count == 1)
        #expect(youtube.priceChanges.first?.from == Decimal(string: "10.29")!)
    }

    /// Apple bills a subscription and a one-off app purchase down the same line. Only a repeating
    /// charge is a subscription; a single charge at a price Apple never published is shopping,
    /// which is how seven purchases once became seven subscriptions.
    @Test func keepsRecurringAppleChargesAndDropsOneOffPurchases() throws {
        let apple = try LocalPipeline.subscriptions().filter { $0.merchant == "Apple" }
        #expect(!apple.isEmpty)
        #expect(apple.allSatisfy { $0.occurrences.count >= 2 })
        #expect(apple.contains { $0.amount == Decimal(string: "11.99")! && $0.confidence == .confident })
    }

    /// Everyday spending on a regular rhythm is excluded by merchant category, not by luck.
    @Test func excludesEverydaySpendingByCategory() throws {
        let merchants = try Set(LocalPipeline.subscriptions().map(\.merchant))
        for everyday in ["McDonald's", "Wolt", "podsey", "Glovo"] {
            #expect(!merchants.contains(everyday), "\(everyday) is not a subscription")
        }
    }

    @Test func inventsNoSubscriptionForMerchantsThatMerelyContainABrand() throws {
        let merchants = try Set(LocalPipeline.subscriptions().map(\.merchant))
        #expect(!merchants.contains("ChatGPT"))
        #expect(!merchants.contains("Zoom"))
    }
}
