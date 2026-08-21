import Catalog
import Core
import Foundation
import Normalization
import PDFKit
import Testing

@testable import Detection
@testable import Ingestion

/// Runs the real TBC statements through the whole pipeline. They are other people's, so they are
/// read where they lie and never copied into the package; everywhere but the author's machine
/// there is nothing to read and the suite skips. Assertions are counts — never a value.
enum LocalTBC {
    static let directory = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "statements")

    static let parser = TBCStatementParser()

    /// Every statement in the folder, whoever's bank wrote it. Read once: extracting four megabytes
    /// of PDF per test turned a half-second suite into a five-second one.
    static let allStatements: [String] = {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "pdf" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                guard let document = PDFDocument(url: url) else { return nil }
                return (0..<document.pageCount)
                    .compactMap { document.page(at: $0)?.string }
                    .joined(separator: "\n")
            }
    }()

    static let statements: [String] = allStatements.filter(parser.canParse)

    static var isAvailable: Bool { !statements.isEmpty }

    /// Every card block carries an MCC and nothing else does, so the label count is the number of
    /// purchases the statement contains — the denominator a parse ratio needs.
    static func cardBlocks(in text: String) -> Int {
        TBCStatementParser.flatten(text).components(separatedBy: "MCC:").count - 1
    }

    static func outcome(in text: String) throws -> DetectionOutcome {
        let catalog = BundledCatalog()
        return SubscriptionDetector(catalog: catalog)
            .analyse(MerchantNormalizer(directory: catalog).normalize(try parser.parse(text)))
    }

    static func subscriptions(in text: String) throws -> [DetectedSubscription] {
        try outcome(in: text).subscriptions
    }
}

@Suite("TBC real statements", .enabled(if: LocalTBC.isAvailable))
struct TBCLocalStatementTests {
    /// The folder holds both banks. A statement belongs to exactly one parser — the BIC appears in
    /// a BOG statement too, on any transfer to a TBC account, which is why it cannot decide alone.
    @Test func claimsTheTBCStatementsAndNoOthers() {
        let bog = BOGStatementParser()
        let all = LocalTBC.allStatements

        #expect(all.count > 3)
        #expect(LocalTBC.statements.count == 3)
        #expect(all.allSatisfy { !(LocalTBC.parser.canParse($0) && bog.canParse($0)) })
    }

    /// §5 calls ~80% of lines sufficient. Every card block parsed or the grammar has drifted.
    @Test func parsesEveryCardPurchase() throws {
        for text in LocalTBC.statements {
            let transactions = try LocalTBC.parser.parse(text)
            #expect(transactions.count == LocalTBC.cardBlocks(in: text))
            #expect(transactions.allSatisfy { $0.amount > 0 })
            #expect(transactions.allSatisfy { $0.currency.count == 3 })
            #expect(transactions.allSatisfy { !$0.rawDescription.isEmpty })
            #expect(transactions.allSatisfy { $0.mcc?.isEmpty == false })
        }
    }

    /// A merchant field that swallowed the next record shows up as an implausible length, which is
    /// how the first draft of the grammar failed.
    @Test func recoversMerchantsWithoutRunningIntoTheNextRecord() throws {
        for text in LocalTBC.statements {
            let transactions = try LocalTBC.parser.parse(text)
            #expect(transactions.allSatisfy { $0.rawDescription.count <= 40 })
            #expect(transactions.allSatisfy { !$0.rawDescription.contains("MCC:") })
        }
    }

    /// Detection needs more than a year, and a date read off the wrong column lands outside it.
    @Test func datesSpanThePeriodTheStatementCovers() throws {
        for text in LocalTBC.statements {
            let dates = try LocalTBC.parser.parse(text).map(\.date)
            let span = try #require(dates.max()).timeIntervalSince(try #require(dates.min()))
            #expect(span > 0)
            #expect(try #require(dates.max()) < Date(timeIntervalSince1970: 2_000_000_000))
        }
    }

    @Test func findsSubscriptionsInTheLongestStatement() throws {
        let longest = try #require(LocalTBC.statements.max { $0.count < $1.count })
        let detected = try LocalTBC.subscriptions(in: longest)

        #expect(!detected.isEmpty)
        #expect(detected.allSatisfy { $0.occurrences.count >= 1 })
    }

    /// Counts, printed for the record. Values never are.
    @Test func reportsTheCounts() throws {
        for (index, text) in LocalTBC.statements.enumerated() {
            let transactions = try LocalTBC.parser.parse(text)
            let detected = try LocalTBC.subscriptions(in: text)
            let dates = transactions.map(\.date).sorted()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let currencies = Set(transactions.map(\.currency)).sorted().joined(separator: "/")
            let catalog = BundledCatalog()
            let normalized = MerchantNormalizer(directory: catalog).normalize(transactions)
            let known = normalized.filter { $0.merchantConfidence == 1 }
            let groups = Dictionary(grouping: normalized) { "\($0.merchant)|\($0.raw.currency)" }
            let repeated = groups.values.filter { $0.count >= 3 }
            let candidates = repeated.filter { $0.allSatisfy { MerchantCategory.canRecur($0.raw) } }
            print(
                """
                TBC statement \(index + 1): \
                \(transactions.count)/\(LocalTBC.cardBlocks(in: text)) card purchases · \
                \(Set(transactions.map(\.rawDescription)).count) distinct merchants · \
                \(currencies) · \
                \(formatter.string(from: dates.first!))…\(formatter.string(from: dates.last!)) · \
                \(known.count) charges at \(Set(known.map(\.merchant)).count) catalog brands · \
                \(repeated.count) merchants charged 3+ times \
                (\(candidates.count) in a category that can recur) · \
                \(LocalTBC.parser.exchangeRates(in: text).count) rates · \
                \(detected.count) subscriptions \
                (\(detected.filter { $0.confidence == .confident }.count) confident) · \
                \(try LocalTBC.outcome(in: text).candidates.count) to ask about
                """)
        }
    }
}
