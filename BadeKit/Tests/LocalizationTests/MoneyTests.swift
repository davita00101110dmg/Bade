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

    @Test func placementFollowsTheLocale() {
        let english = amount.formatted(.badeMoney("GEL").locale(Locale(identifier: "en_US")))
        let georgian = amount.formatted(.badeMoney("GEL").locale(Locale(identifier: "ka_GE")))
        #expect(english.hasPrefix("₾"))
        #expect(georgian.hasSuffix("₾"))
    }
}
