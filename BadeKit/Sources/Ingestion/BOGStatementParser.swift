import Core
import Foundation

/// Bank of Georgia statement export. Card purchases only — transfers, fees and deposits
/// are not subscriptions. Bade is not affiliated with the bank; the name identifies the format.
public struct BOGStatementParser: StatementParser {
    public static let identifier = "bog-pdf-v1"
    public static let displayName = "Bank of Georgia"

    public init() {}

    public func canParse(_ text: String) -> Bool {
        vocabulary(for: Self.flatten(text)) != nil
    }

    public func parse(_ text: String) throws -> [RawTransaction] {
        let flat = Self.flatten(text)
        guard let vocabulary = vocabulary(for: flat) else {
            throw StatementParsingError.unrecognisedFormat
        }

        let transactions =
            flat
            .components(separatedBy: vocabulary.recordStart)
            .dropFirst()
            .compactMap { BOGPaymentRecord(body: $0[...], vocabulary: vocabulary)?.transaction }

        guard !transactions.isEmpty else {
            throw StatementParsingError.suspiciouslyFewTransactions(found: 0)
        }
        return transactions
    }

    /// Read in both languages rather than the one the header suggests. The rows are laid out
    /// identically either way and the two label sets share nothing, so whichever the export used
    /// is the only one that matches — and a run of conversions carries no merchant label to
    /// recognise the statement by in the first place.
    public func exchangeRates(in text: String) -> [ObservedRate] {
        let flat = Self.flatten(text)
        return BOGVocabulary.all.flatMap { BOGExchangeRecord.rates(in: flat, vocabulary: $0) }
    }

    private func vocabulary(for flat: String) -> BOGVocabulary? {
        BOGVocabulary.all.first { flat.contains($0.merchant) }
    }

    /// Extraction wraps fields mid-value, merges records onto shared lines and injects page
    /// footers, so line structure carries no meaning; fields are recovered from their labels.
    static func flatten(_ text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
