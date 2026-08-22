import Foundation

/// Reads a typed amount. A decimal pad shows whichever separator the locale uses, and a phone set
/// to Georgian will offer a comma for the same number an English one writes with a full stop, so
/// both are accepted. Reading input, not formatting output — money is still displayed via `Locale`.
enum DecimalInput {
    /// How long a typed amount may get. Nothing stopped it before, so a decimal pad held down
    /// produced an amount of any length at all — which then had to be totalled, laid out in a row,
    /// drawn on a widget and read aloud.
    ///
    /// Six characters: 999.99 with decimals, or 999999 without. A subscription is not larger than
    /// that. On characters rather than on value, because the field is text until it parses and a
    /// half-typed number has no value to judge yet.
    static let characterLimit = 6

    /// Truncates rather than refuses.
    ///
    /// Refusing was tried first and does not work: when a binding's setter leaves the source of
    /// truth alone, SwiftUI does not push the old value back into the field, so typing carried on
    /// unbounded and the limit only appeared to apply when the field lost focus. Returning a
    /// shorter string changes the value, which is what makes SwiftUI write it back on the keystroke.
    static func limited(_ text: String) -> String { String(text.prefix(characterLimit)) }

    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(
            of: ",", with: ".")
        guard let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }
}
