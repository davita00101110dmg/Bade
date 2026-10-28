import Foundation

/// Numbers in either convention a statement may print them: `1,240.50` or `1.240,50`.
enum StatementNumber {
    private static let separators: Set<Character> = [".", ","]

    /// The last separator is the decimal point when one or two digits follow it; others group.
    static func amount(_ text: some StringProtocol) -> Decimal? {
        var whole = String(text)
        var fraction = ""
        if let point = whole.lastIndex(where: separators.contains),
            (1...2).contains(whole.distance(from: point, to: whole.endIndex) - 1)
        {
            fraction = String(whole[whole.index(after: point)...])
            whole = String(whole[..<point])
        }
        whole.removeAll(where: separators.contains)
        return Decimal(string: fraction.isEmpty ? whole : "\(whole).\(fraction)")
    }

    /// A rate is never grouped, so its one separator is the decimal point, comma or not.
    static func rate(_ text: some StringProtocol) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: "."))
    }
}
