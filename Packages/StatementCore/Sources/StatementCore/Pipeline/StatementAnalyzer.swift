import Foundation

/// `BadeKit`'s `StatementImporter` from the extracted text onward. Turning PDF bytes into that text
/// needs PDFKit, so it stays in the app, which hands the result here.
public struct StatementAnalyzer: Sendable {
    private let parsers: [any StatementParser] = [BOGStatementParser(), TBCStatementParser()]
    private let catalog = BundledCatalog()

    public init() {}

    public func analyse(text: String) throws(ImportError) -> ImportResult {
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
}
