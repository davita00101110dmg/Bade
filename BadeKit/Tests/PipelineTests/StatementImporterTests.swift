import Core
import Foundation
import Testing

@testable import Pipeline

private let importer = StatementImporter()

private func statement(_ text: String) -> Data { Data(text.utf8) }

private let onePurchase = """
    Payment - Amount: GEL15.20; Merchant: PAYPAL *SPOTIFY*P42A20, United Kingdom; MCC:4816; \
    Date: 20/05/2026 00:00;
    """

@Suite("Statement importer")
struct StatementImporterTests {
    @Test func composesParsingNormalisationAndDetection() async throws {
        let statement = statement(
            (1...3).map { month in
                "Payment - Amount: GEL15.20; Merchant: PAYPAL *SPOTIFY*P4\(month)A20, "
                    + "United Kingdom; MCC:4816; Date: 20/0\(month + 4)/2026 00:00; "
            }.joined())

        let result = try await importer.detectSubscriptions(in: statement)
        #expect(result.detected.count == 1)
        #expect(result.detected.first?.merchant == "Spotify")
        #expect(result.transactionCount == 3)
    }

    @Test func reportsTheStatementPeriod() async throws {
        let result = try await importer.detectSubscriptions(in: statement(onePurchase))
        let period = try #require(result.period)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        #expect(calendar.component(.month, from: period.lowerBound) == 5)
    }

    @Test func collectsConversionRatesForTotals() async throws {
        let withRate = """
            Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, United States; MCC:4899; \
            Date: 27/05/2026 00:00; Card scheme conversion rate (USD-GEL): 2.6317; \
            Bank conversion rate (USD-GEL): 2.6716;
            """
        let result = try await importer.detectSubscriptions(in: statement(withRate))
        #expect(result.rates.rate(from: "USD", to: "GEL") == Decimal(string: "2.6716")!)
    }

    /// Features present these; a Swift error description must never reach the user (§5).
    @Test func reportsUnrecognisedFormatsInTheCoreVocabulary() async {
        await #expect(throws: ImportError.unrecognisedFormat) {
            try await importer.detectSubscriptions(in: statement("a shopping list, not a statement"))
        }
    }

    @Test func reportsAnEmptyFileAsUnreadable() async {
        await #expect(throws: ImportError.unreadableFile) {
            try await importer.detectSubscriptions(in: Data())
        }
    }
}
