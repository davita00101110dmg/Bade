import Foundation

/// Reads a typed amount. A decimal pad shows whichever separator the locale uses, and a phone set
/// to Georgian will offer a comma for the same number an English one writes with a full stop, so
/// both are accepted. Reading input, not formatting output — money is still displayed via `Locale`.
enum DecimalInput {
    /// Digits before the separator. Six reaches 999,999, which is past any subscription.
    static let wholeDigitLimit = 6
    /// Digits after it. Money has two, and a third has nowhere to be displayed.
    static let fractionDigitLimit = 2

    /// Bounds the number rather than the string.
    ///
    /// A flat character count was the first attempt and it was the wrong shape: six characters meant
    /// "999.99" cost the same budget as "999999", so entering a large amount silently spent the
    /// allowance that the tetri needed. The two halves are counted separately instead, so the
    /// decimals are always reachable no matter how big the whole part is.
    ///
    /// Anything that is neither a digit nor a separator is dropped, and a second separator with it —
    /// unreachable from a decimal pad, but a paste is not a keyboard.
    ///
    /// Truncates rather than refuses, and the field that shows it keeps its own copy: a `TextField`
    /// driven by a computed `Binding` will not take a shorter value back from its own setter, so
    /// bounding this here alone stopped nothing on a phone.
    static func limited(_ text: String) -> String {
        var whole = ""
        var fraction = ""
        var separator: Character?

        for character in text {
            if character.isNumber {
                if separator == nil {
                    if whole.count < wholeDigitLimit { whole.append(character) }
                } else if fraction.count < fractionDigitLimit {
                    fraction.append(character)
                }
            } else if separator == nil, character == "." || character == "," {
                // Kept exactly as typed: a Georgian keyboard offers a comma, and `parse` is what
                // reconciles the two.
                separator = character
            }
        }

        guard let separator else { return whole }
        return whole + String(separator) + fraction
    }

    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(
            of: ",", with: ".")
        guard let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }
}
