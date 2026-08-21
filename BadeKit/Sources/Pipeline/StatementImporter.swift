import Catalog
import Core
import Detection
import Foundation
import Ingestion
import Normalization
import PDFKit

public struct StatementImporter: StatementImporting {
    private let parsers: [any StatementParser] = [BOGStatementParser(), TBCStatementParser()]
    private let catalog = BundledCatalog()

    public init() {}

    public func detectSubscriptions(in statement: Data) async throws -> ImportResult {
        let text = Self.text(from: statement)
        guard !text.isEmpty else { throw ImportError.unreadableFile }
        guard let parser = parsers.first(where: { $0.canParse(text) }) else {
            throw ImportError.unrecognisedFormat
        }

        let transactions: [RawTransaction]
        do {
            transactions = try parser.parse(text)
        } catch StatementParsingError.suspiciouslyFewTransactions {
            throw ImportError.tooFewTransactions
        } catch {
            throw ImportError.unrecognisedFormat
        }
        var rates = RateBook()
        for transaction in transactions {
            guard let conversion = transaction.conversion else { continue }
            rates.record(conversion, on: transaction.date)
        }
        for rate in parser.exchangeRates(in: text) { rates.record(rate) }

        let dates = transactions.map(\.date)
        let normalized = MerchantNormalizer(directory: catalog).normalize(transactions)
        let outcome = SubscriptionDetector(catalog: catalog).analyse(normalized)
        return ImportResult(
            detected: outcome.subscriptions,
            candidates: outcome.candidates,
            rates: rates,
            transactionCount: transactions.count,
            period: dates.min().flatMap { low in dates.max().map { low...$0 } })
    }

    /// Statement bytes stay in memory and are never written to disk (§10).
    private static func text(from data: Data) -> String {
        guard let document = PDFDocument(data: data) else {
            return String(decoding: data, as: UTF8.self)
        }
        return (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
    }
}
