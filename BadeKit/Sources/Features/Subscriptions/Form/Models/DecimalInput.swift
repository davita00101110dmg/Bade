import Foundation

/// Reads a typed amount. A decimal pad shows whichever separator the locale uses, and a phone set
/// to Georgian will offer a comma for the same number an English one writes with a full stop, so
/// both are accepted. Reading input, not formatting output — money is still displayed via `Locale`.
enum DecimalInput {
    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(
            of: ",", with: ".")
        guard let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }
}
