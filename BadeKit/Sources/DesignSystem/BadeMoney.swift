import Foundation

extension FormatStyle where Self == Decimal.FormatStyle.Currency {
    /// Always renders the currency's symbol — ₾, $, € — rather than falling back to its ISO code
    /// as the standard presentation does for anything the locale has no shorthand for. Placement
    /// still follows the locale, so Georgian gets `42,45 ₾` and English `₾42.45`.
    public static func badeMoney(_ code: String) -> Decimal.FormatStyle.Currency {
        .currency(code: code).presentation(.narrow)
    }
}
