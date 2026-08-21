import Foundation
import Testing

@testable import DesignSystem

@Suite("Money split")
struct BadeMoneySplitTests {
    private let english = Locale(identifier: "en_US")
    private let georgian = Locale(identifier: "ka_GE")

    @Test func setsTheTetriApartFromTheLari() {
        let split = BadeMoneySplit(Decimal(string: "103.94")!, currency: "GEL", locale: english)

        #expect(split.head == "₾103")
        #expect(split.fraction == ".94")
        #expect(split.tail.isEmpty)
    }

    /// Georgian puts the symbol after the amount, so the fraction is not the end of the string and
    /// a naive "everything after the separator" would shrink the ₾ along with the tetri.
    @Test func leavesTheSymbolFullSizeWhereTheLocalePutsItLast() throws {
        let split = BadeMoneySplit(Decimal(string: "103.94")!, currency: "GEL", locale: georgian)
        let separator = try #require(georgian.decimalSeparator)

        #expect(split.fraction == "\(separator)94")
        #expect(split.tail.contains("₾"))
        #expect(!split.fraction.contains("₾"))
    }

    @Test(arguments: [
        "0", "0.05", "9.99", "103.94", "1234.5", "999999.99",
    ])
    func losesNothingOfWhatWasFormatted(amount: String) {
        for locale in [english, georgian] {
            let value = Decimal(string: amount)!
            let split = BadeMoneySplit(value, currency: "GEL", locale: locale)

            #expect(
                split.head + split.fraction + split.tail
                    == value.formatted(.badeMoney("GEL").locale(locale)))
        }
    }

    /// Two digits always, so the figure never changes width as the tetri land on a round number.
    @Test(arguments: ["10", "10.5", "10.50", "10.549"])
    func alwaysShowsTwoTetriDigits(amount: String) {
        let split = BadeMoneySplit(Decimal(string: amount)!, currency: "GEL", locale: english)

        #expect(split.fraction.count == 3)
    }

    /// A currency the locale prints without a fraction leaves the small type empty rather than
    /// inventing digits — the split describes what was formatted, it does not reformat.
    @Test func printsNoFractionWhereTheCurrencyHasNone() {
        let split = BadeMoneySplit(1234, currency: "JPY", locale: english)

        #expect(split.fraction.isEmpty)
        #expect(split.tail.isEmpty)
        #expect(split.head.contains("1,234"))
    }
}
