import Foundation

/// Reads a typed amount. A decimal pad shows whichever separator the locale uses, and a phone set
/// to Georgian will offer a comma for the same number an English one writes with a full stop, so
/// both are accepted. Reading input, not formatting output — money is still displayed via `Locale`.
enum DecimalInput {
    /// How long a typed amount may get. Nothing stopped it before, so a decimal pad held down
    /// produced an amount of any length at all — which then had to be totalled, laid out in a row
    /// and read aloud.
    ///
    /// Twelve characters reaches 999,999,999.99, which is past any subscription anyone will ever
    /// enter and still short enough that the field cannot outgrow the row it sits in. A limit on
    /// characters rather than on value, because the field is text until it parses and a partly
    /// typed number has no value to judge.
    static let characterLimit = 12

    /// Refuses rather than truncates: the extra character simply never appears, which is how a
    /// full field behaves everywhere else on iOS.
    static func isWithinLimit(_ text: String) -> Bool { text.count <= characterLimit }

    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(
            of: ",", with: ".")
        guard let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }
}
