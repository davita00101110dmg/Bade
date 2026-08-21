import Foundation

extension FormatStyle where Self == Decimal.FormatStyle.Currency {
    /// Always renders the currency's symbol — ₾, $, € — rather than falling back to its ISO code
    /// as the standard presentation does for anything the locale has no shorthand for. Placement
    /// still follows the locale, so Georgian gets `42,45 ₾` and English `₾42.45`.
    public static func badeMoney(_ code: String) -> Decimal.FormatStyle.Currency {
        .currency(code: code).presentation(.narrow)
    }

    /// Headline figures drop the tetri: at this size the decimals are noise, and the point of the
    /// number is its magnitude rather than its precision.
    public static func badeMoneyWhole(_ code: String) -> Decimal.FormatStyle.Currency {
        badeMoney(code).precision(.fractionLength(0))
    }
}

extension String {
    /// The currency's symbol alone — ₾, $, €. Taken from the same format the app renders money
    /// with, so a symbol shown on its own can never disagree with the one inside a total.
    public static func badeCurrencySymbol(_ code: String, in locale: Locale) -> String {
        Decimal.zero.formatted(.badeMoney(code).locale(locale))
            .filter { !$0.isNumber && !$0.isWhitespace && !$0.isPunctuation }
    }
}
