import Core
import Foundation
import Testing

@testable import Ingestion

/// Real statements are personal data and are never committed; these run only where the fixture
/// exists locally and skip cleanly everywhere else.
enum LocalStatement {
    static let directory = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Fixtures/local")

    static func text(_ name: String) -> String? {
        try? String(contentsOf: directory.appending(path: name), encoding: .utf8)
    }

    static func labelledPurchases(in text: String) -> Int {
        let flat = BOGStatementParser.flatten(text)
        return flat.components(separatedBy: "Merchant:").count - 1
            + flat.components(separatedBy: "ობიექტი:").count - 1
    }

    static var isAvailable: Bool { text("bog-statement-full-en.txt") != nil }
}

@Suite("BOG real statement", .enabled(if: LocalStatement.isAvailable))
struct BOGLocalStatementTests {
    private let parser = BOGStatementParser()
    private let subscriptions = ["YouTubePremium", "SETANTA", "AMZ*Adobe", "Epidemic Sound", "SPOTIFY", "APPLE.COM/BILL"]

    /// §5 calls ~80% of lines sufficient; anything below 95% here means a real regression.
    @Test(arguments: ["bog-statement-full-en.txt", "bog-statement-full-ka.txt"])
    func parsesNearlyEveryPurchase(fixture: String) throws {
        let text = try #require(LocalStatement.text(fixture))
        let transactions = try parser.parse(text)
        let labelled = LocalStatement.labelledPurchases(in: text)

        #expect(Double(transactions.count) / Double(labelled) >= 0.95)
        #expect(transactions.allSatisfy { $0.amount > 0 })
        #expect(transactions.allSatisfy { $0.currency.count == 3 })
        #expect(transactions.allSatisfy { !$0.rawDescription.isEmpty })
    }

    @Test func bothLanguagesAgreeOnSubscriptionCharges() throws {
        let english = try parser.parse(#require(LocalStatement.text("bog-statement-full-en.txt")))
        let georgian = try parser.parse(#require(LocalStatement.text("bog-statement-full-ka.txt")))

        func charges(_ transactions: [RawTransaction]) -> Set<String> {
            Set(
                transactions
                    .filter { t in subscriptions.contains { t.rawDescription.contains($0) } }
                    .map { "\($0.date)|\($0.amount)|\($0.rawDescription)" })
        }
        #expect(charges(english) == charges(georgian))
    }

    @Test func recoversTheYouTubePriceRise() throws {
        let transactions = try parser.parse(#require(LocalStatement.text("bog-statement-full-en.txt")))
        let youtube = transactions
            .filter { $0.rawDescription.contains("YouTubePremium") }
            .sorted { $0.date < $1.date }

        #expect(Set(youtube.map(\.amount)) == [Decimal(string: "10.29")!, Decimal(string: "17.49")!])
        #expect(youtube.first?.amount == Decimal(string: "10.29")!)
        #expect(youtube.last?.amount == Decimal(string: "17.49")!)
    }

    @Test func recoversEverySubscriptionMerchant() throws {
        let transactions = try parser.parse(#require(LocalStatement.text("bog-statement-full-en.txt")))
        for merchant in subscriptions {
            #expect(transactions.contains { $0.rawDescription.contains(merchant) }, "\(merchant) missing")
        }
    }

    /// The trimmed fixture is the candidate for publication; it must stay parseable on its own.
    @Test func trimmedFixtureStillParses() throws {
        let text = try #require(LocalStatement.text("bog-statement-01.txt"))
        #expect(try parser.parse(text).count > 50)
    }
}
