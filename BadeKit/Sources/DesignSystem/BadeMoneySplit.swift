import Foundation
import Localization

/// Formatted money cut into the part before the tetri, the tetri themselves, and whatever the
/// locale places after them. English ends on the fraction (`₾103.94`); Georgian does not
/// (`103,94 ₾`), so the symbol must not be swept into the smaller type along with the digits.
public struct BadeMoneySplit: Equatable, Sendable {
    public let head: String
    /// The decimal separator and the digits after it, or empty where the locale printed none.
    public let fraction: String
    public let tail: String

    public init(_ amount: Decimal, currency: String, locale: Locale) {
        let text = amount.formatted(.badeMoney(currency).locale(locale))
        guard let separator = locale.decimalSeparator,
            let range = text.range(
                of: "\(NSRegularExpression.escapedPattern(for: separator))\\d+",
                options: [.regularExpression, .backwards])
        else {
            head = text
            fraction = ""
            tail = ""
            return
        }
        head = String(text[text.startIndex..<range.lowerBound])
        fraction = String(text[range])
        tail = String(text[range.upperBound...])
    }
}
