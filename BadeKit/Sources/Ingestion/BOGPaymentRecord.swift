import Core
import Foundation

/// One card purchase, recovered from its labels rather than its position on the page.
struct BOGPaymentRecord {
    // Regex is not Sendable, so these are computed rather than shared constants.
    private static var amountPattern: Regex<(Substring, Substring, Substring)> {
        /([A-Z]{3})\s*([0-9,]+\.[0-9]{2})/
    }
    private static var datePattern: Regex<(Substring, Substring, Substring, Substring)> {
        /([0-9]{2})\/([0-9]{2})\/([0-9]{4})/
    }
    private static var ratePattern: Regex<(Substring, Substring, Substring, Substring, Substring)> {
        /(Card scheme|Bank) conversion rate \(([A-Z]{3})-([A-Z]{3})\):\s*([0-9.]+)/
    }

    let transaction: RawTransaction

    /// `body` runs from just after the record-start label to the start of the next record.
    init?(body: Substring, vocabulary: BOGVocabulary) {
        guard let merchant = body.field(after: vocabulary.merchant, upTo: "; MCC:"),
            let money = try? Self.amountPattern.firstMatch(in: body),
            let amount = Decimal(string: money.2.replacingOccurrences(of: ",", with: "")),
            let dateField = body.range(of: vocabulary.date),
            let stamp = try? Self.datePattern.firstMatch(in: body[dateField.upperBound...]),
            let date = Self.date(day: stamp.1, month: stamp.2, year: stamp.3)
        else { return nil }

        transaction = RawTransaction(
            date: date,
            rawDescription: merchant,
            amount: amount,
            currency: String(money.1),
            sourceLine: body.prefix(Self.sourceLineLimit).trimmingCharacters(in: .whitespaces),
            mcc: body.field(after: "MCC:", upTo: ";"),
            conversion: Self.conversion(in: body)
        )
    }

    private static let sourceLineLimit = 240

    /// Statements print the scheme's reference rate and the bank's own; the gap is the markup.
    private static func conversion(in body: Substring) -> CurrencyConversion? {
        var scheme: Decimal?
        var bank: Decimal?
        var pair: (String, String)?
        for match in body.matches(of: ratePattern) {
            guard let value = Decimal(string: String(match.4)) else { continue }
            pair = (String(match.2), String(match.3))
            if match.1 == "Bank" { bank = value } else { scheme = value }
        }
        guard let pair, let bank = bank ?? scheme else { return nil }
        return CurrencyConversion(
            from: pair.0, to: pair.1, bankRate: bank, schemeRate: scheme)
    }

    private static func date(day: Substring, month: Substring, year: Substring) -> Date? {
        guard let day = Int(day), let month = Int(month), let year = Int(year) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}

extension Substring {
    /// The value between a field's label and its terminator, or to the end if the record was cut short.
    func field(after label: String, upTo terminator: String) -> String? {
        guard let start = range(of: label) else { return nil }
        let rest = self[start.upperBound...]
        let end = rest.range(of: terminator)?.lowerBound ?? rest.endIndex
        let value = rest[..<end].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }
}
