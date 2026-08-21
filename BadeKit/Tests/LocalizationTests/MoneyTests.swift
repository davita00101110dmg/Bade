import Foundation
import Testing

@testable import Localization

@Suite("Money formatting")
struct MoneyTests {
    private let amount = Decimal(string: "42.45")!

    /// The standard presentation renders "GEL 42.45" next to "$42.45", which reads inconsistently.
    @Test(arguments: [("GEL", "₾"), ("USD", "$"), ("EUR", "€"), ("TRY", "₺"), ("AMD", "֏")])
    func alwaysShowsTheSymbol(code: String, symbol: String) {
        let formatted = amount.formatted(.badeMoney(code).locale(Locale(identifier: "en_US")))
        #expect(formatted.contains(symbol), "\(code) rendered as \(formatted)")
        #expect(!formatted.contains(code), "\(code) fell back to its ISO code")
    }

    /// The symbol on its own comes out of the same format a total is rendered with, so the two can
    /// never disagree — and it must survive the locale putting the symbol at either end.
    @Test(arguments: ["en_US", "ka_GE"])
    func liftsTheSymbolOutOfTheFormat(identifier: String) {
        let locale = Locale(identifier: identifier)

        #expect(String.badeCurrencySymbol("GEL", in: locale) == "₾")
        #expect(String.badeCurrencySymbol("USD", in: locale) == "$")
    }

    @Test func placementFollowsTheLocale() {
        let english = amount.formatted(.badeMoney("GEL").locale(Locale(identifier: "en_US")))
        let georgian = amount.formatted(.badeMoney("GEL").locale(Locale(identifier: "ka_GE")))
        #expect(english.hasPrefix("₾"))
        #expect(georgian.hasSuffix("₾"))
    }
}
