import Foundation
import Testing

@testable import Detection

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
