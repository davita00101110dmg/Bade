import Core
import Foundation

/// TBC Bank statement export. Card purchases only — transfers, fees and deposits are not
/// subscriptions. Bade is not affiliated with the bank; the name identifies the format.
public struct TBCStatementParser: StatementParser {
    public static let identifier = "tbc-pdf-v1"
    public static let displayName = "TBC Bank"

    /// The bank's own BIC, printed against every row. It names the format without reading a value.
    static let signature = "TBCBGE22"
    /// Every card purchase opens with the terminal marker. Descriptions mention it too, which is
    /// why a body still has to prove itself a record.
    private static let recordStart = "POS "

    public init() {}

    /// The BIC alone is not enough: any bank prints it on a transfer to a TBC account, and a
    /// Liberty statement that mentions it once was claimed here before a record had to be found too.
    public func canParse(_ text: String) -> Bool {
        let flat = Self.flatten(text)
        return flat.contains(Self.signature) && Self.records(in: flat).first != nil
    }

    public func parse(_ text: String) throws -> [RawTransaction] {
        let flat = Self.flatten(text)
        guard flat.contains(Self.signature) else {
            throw StatementParsingError.unrecognisedFormat
        }

        let transactions = Array(Self.records(in: flat))
        guard !transactions.isEmpty else {
            throw StatementParsingError.suspiciouslyFewTransactions(found: 0)
        }
        return transactions
    }

    /// Lazy, so recognising a format costs one record rather than all of them.
    private static func records(in flat: String) -> some Collection<RawTransaction> {
        flat.components(separatedBy: recordStart)
            .dropFirst()
            .lazy
            .compactMap { TBCCardRecord(body: $0[...])?.transaction }
    }

    public func exchangeRates(in text: String) -> [ObservedRate] {
        TBCExchangeRecord.rates(in: Self.flatten(text))
    }

    /// Extraction wraps a row across lines and emits its columns as separate blocks, so line
    /// structure carries no meaning; a record is recovered from the run the bank prints intact.
    static func flatten(_ text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
