import Foundation
import Testing

@testable import StatementCore

private let analyzer = StatementAnalyzer()

private func statement(_ text: String) -> String { text }

private let onePurchase = """
    Payment - Amount: GEL15.20; Merchant: PAYPAL *SPOTIFY*P42A20, United Kingdom; MCC:4816; \
    Date: 20/05/2026 00:00;
    """

@Suite("Statement analyzer")
struct StatementAnalyzerTests {
    @Test func composesParsingNormalisationAndDetection() throws {
        let statement = statement(
            (1...3).map { month in
                "Payment - Amount: GEL15.20; Merchant: PAYPAL *SPOTIFY*P4\(month)A20, "
                    + "United Kingdom; MCC:4816; Date: 20/0\(month + 4)/2026 00:00; "
            }.joined())

        let result = try analyzer.analyse(text: statement)
        #expect(result.detected.count == 1)
        #expect(result.detected.first?.merchant == "Spotify")
        #expect(result.transactionCount == 3)
    }

    @Test func reportsTheStatementPeriod() throws {
        let result = try analyzer.analyse(text: statement(onePurchase))
        let period = try #require(result.period)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        #expect(calendar.component(.month, from: period.lowerBound) == 5)
    }

    @Test func collectsConversionRatesForTotals() throws {
        let withRate = """
            Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, United States; MCC:4899; \
            Date: 27/05/2026 00:00; Card scheme conversion rate (USD-GEL): 2.6317; \
            Bank conversion rate (USD-GEL): 2.6716;
            """
        let result = try analyzer.analyse(text: statement(withRate))
        #expect(result.rates.rate(from: "USD", to: "GEL", on: Date(timeIntervalSince1970: 1_760_000_000)) == Decimal(string: "2.6716")!)
    }

    /// Features present these; a Swift error description must never reach the user (§5).
    @Test func reportsUnrecognisedFormatsInTheCoreVocabulary() {
        #expect(throws: ImportError.unrecognisedFormat) {
            try analyzer.analyse(text: statement("a shopping list, not a statement"))
        }
    }

    @Test func reportsAnEmptyFileAsUnreadable() {
        #expect(throws: ImportError.unreadableFile) {
            try analyzer.analyse(text: "")
        }
    }
}
