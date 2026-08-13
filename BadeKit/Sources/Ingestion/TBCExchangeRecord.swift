import Core
import Foundation

/// The account holder's own conversions between their balances, which TBC prints inline with the
/// rate it gave them. A handful appear in a year — but they are the only rate the statement states
/// outright, and a card charge settled in a foreign currency has none of its own.
enum TBCExchangeRecord {
    // Regex is not Sendable, so these are computed rather than shared constants.
    private static var ratePattern:
        Regex<(Substring, Substring, Substring, Substring, Substring)>
    {
        /\([^()]{0,40}?([0-9]+)\s*([A-Z]{3})\s*=\s*([0-9]+\.[0-9]+)\s*([A-Z]{3})\)/
    }
    private static var datePattern: Regex<(Substring, Substring, Substring, Substring)> {
        /([0-9]{2})\/([0-9]{2})\/([0-9]{4})/
    }

    /// Weak currencies are quoted per 10 or per 100; dividing by the quantity keeps the rate per unit.
    static func rates(in flat: String) -> [ObservedRate] {
        let days = flat.matches(of: datePattern).compactMap { match -> (String.Index, Date)? in
            StatementDate.from(day: match.1, month: match.2, year: match.3)
                .map { (match.range.lowerBound, $0) }
        }

        return flat.matches(of: ratePattern).compactMap { match in
            guard let quantity = Decimal(string: String(match.1)), quantity > 0,
                let rate = Decimal(string: String(match.3)),
                let date = days.last(where: { $0.0 < match.range.lowerBound })?.1
            else { return nil }
            return ObservedRate(
                date: date, from: String(match.2), to: String(match.4), rate: rate / quantity)
        }
    }
}
