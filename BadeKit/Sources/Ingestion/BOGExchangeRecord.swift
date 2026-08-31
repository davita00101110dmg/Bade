import Core
import Foundation

/// The account holder's own currency conversions, which the statement prints with both sides and
/// the rate. They carry no merchant, so they are not transactions — but they are the only place a
/// EUR or GBP rate appears at all when those charges settle from a balance in their own currency.
enum BOGExchangeRecord {
    // Regex is not Sendable, so these are computed rather than shared constants.
    private static func exchangePattern(_ language: BOGVocabulary.Language)
        -> Regex<(Substring, Substring, Substring, Substring, Substring)>
    {
        switch language {
        case .english:
            /Amount:? ([A-Z]{3})([0-9,]+(?:\.[0-9]+)?); Foreign Exchange\. FX Rate:[0-9.]+\. Counter-amount: ([A-Z]{3})([0-9,]+(?:\.[0-9]+)?)/
        case .georgian:
            /თანხა:? ([A-Z]{3})([0-9,]+(?:\.[0-9]+)?); ვალუტის გაცვლითი ოპერაცია\. კურსი:[0-9.]+\s*კონტრთანხა: ([A-Z]{3})([0-9,]+(?:\.[0-9]+)?)/
        }
    }

    private static var datePattern: Regex<(Substring, Substring, Substring, Substring)> {
        /([0-9]{2})\/([0-9]{2})\/([0-9]{4})/
    }

    /// The rate is derived from the two amounts rather than read from the printed `FX Rate`, which
    /// is quoted lari-per-foreign whichever way round the conversion went.
    static func rates(in flat: String, vocabulary: BOGVocabulary) -> [ObservedRate] {
        let days = flat.matches(of: datePattern)
            .compactMap { match -> (index: String.Index, date: Date)? in
                StatementDate.from(day: match.1, month: match.2, year: match.3)
                    .map { (match.range.lowerBound, $0) }
            }

        return flat.matches(of: exchangePattern(vocabulary.language)).compactMap { match in
            guard let from = amount(match.2), let to = amount(match.4), from > 0,
                let date = lastDay(in: days, before: match.range.lowerBound)
            else { return nil }
            return ObservedRate(
                date: date, from: String(match.1), to: String(match.3), rate: to / from)
        }
    }

    /// A row's date sits in the table column ahead of it, not inside the record.
    private static func lastDay(
        in days: [(index: String.Index, date: Date)], before index: String.Index
    ) -> Date? {
        days.last { $0.index < index }?.date
    }

    private static func amount(_ text: Substring) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: ""))
    }
}
