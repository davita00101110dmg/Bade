import Foundation
import Testing

@testable import Core

@Suite("Amount tolerance")
struct AmountToleranceTests {
    @Test(arguments: [("100.00", "108.00"), ("100.00", "92.60"), ("35.99", "35.99")])
    func matchesWithinEightPercent(lhs: String, rhs: String) {
        #expect(AmountTolerance.matches(Decimal(string: lhs)!, Decimal(string: rhs)!))
    }

    @Test(arguments: [("100.00", "109.00"), ("100.00", "80.00"), ("35.99", "0")])
    func rejectsOutsideEightPercent(lhs: String, rhs: String) {
        #expect(!AmountTolerance.matches(Decimal(string: lhs)!, Decimal(string: rhs)!))
    }

    @Test func isSymmetric() {
        let low = Decimal(string: "92.60")!
        let high = Decimal(string: "100.00")!
        #expect(AmountTolerance.matches(low, high) == AmountTolerance.matches(high, low))
    }

    @Test func treatsZeroAsItsOwnLevel() {
        #expect(AmountTolerance.matches(0, 0))
        #expect(!AmountTolerance.matches(0, Decimal(string: "0.01")!))
    }
}
