import Foundation
import Testing

@testable import Detection

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

@Suite("Cadence resolver")
struct CadenceResolverTests {
    private let resolver = CadenceResolver()

    @Test func uniformRequiresEveryGapToAgree() {
        let steady = [day("2026-01-09"), day("2026-02-09"), day("2026-03-09")]
        let interrupted = [day("2026-01-09"), day("2026-02-09"), day("2026-09-09")]

        #expect(resolver.uniformCadence(for: steady) == .monthly)
        #expect(resolver.uniformCadence(for: interrupted) == nil)
    }

    @Test func majorityRuleToleratesOneGap() {
        let interrupted = [
            day("2026-01-09"), day("2026-02-09"), day("2026-03-09"),
            day("2026-09-09"), day("2026-10-09"),
        ]
        #expect(resolver.cadence(for: interrupted) == .monthly)
    }

    @Test func rejectsWhenMostGapsDisagree() {
        let noisy = [
            day("2026-01-09"), day("2026-02-09"), day("2026-05-20"), day("2026-08-01"),
        ]
        #expect(resolver.cadence(for: noisy) == nil)
    }

    @Test func needsTwoDatesToHaveAnyCadence() {
        #expect(resolver.cadence(for: [day("2026-01-09")]) == nil)
        #expect(resolver.cadence(for: []) == nil)
    }
}
