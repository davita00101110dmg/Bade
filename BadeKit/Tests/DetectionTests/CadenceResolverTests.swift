import Core
import Foundation
import Testing

@testable import Detection

@Suite("Cadence resolver")
struct CadenceResolverTests {
    private let resolver = CadenceResolver()

    @Test func timelineRequiresEveryChargeOnRhythm() {
        let steady = [day("2026-01-09"), day("2026-02-09"), day("2026-03-09")]
        let offRhythm = [day("2026-01-09"), day("2026-02-09"), day("2026-02-20")]

        #expect(resolver.timelineCadence(for: steady) == .monthly)
        #expect(resolver.timelineCadence(for: offRhythm) == nil)
    }

    /// A missed period is not a broken rhythm. A subscription cancelled and resumed is one
    /// timeline, and breaking it up by amount is how it disappears.
    @Test func timelineAllowsAMissedPeriod() {
        let resumed = [day("2026-01-09"), day("2026-02-09"), day("2026-09-09")]

        #expect(resolver.timelineCadence(for: resumed) == .monthly)
    }

    /// The failure real data exposed. Every charge lands within days of the same point in the
    /// month, but consecutive gaps of 31, 29 and 32 put it outside a delta window, so the timeline
    /// was broken up by amount and a plainly monthly subscription went unreported.
    @Test func timelineReadsASubscriptionWhoseGapsTheCalendarStretched() {
        let stretched = [
            day("2026-01-30"), day("2026-03-02"), day("2026-03-31"), day("2026-05-02"),
        ]

        #expect(resolver.timelineCadence(for: stretched) == .monthly)
    }

    /// A charge retried a couple of days late is the same subscription.
    @Test func timelineToleratesAChargeThatPostedLate() {
        let slipped = [day("2026-01-09"), day("2026-02-11"), day("2026-03-09")]

        #expect(resolver.timelineCadence(for: slipped) == .monthly)
    }

    /// Quarterly is not monthly with two months missing every time.
    @Test func timelinePrefersTheLongestCadenceThatFits() {
        let quarterly = [day("2026-01-09"), day("2026-04-09"), day("2026-07-09")]
        let annual = [day("2024-03-02"), day("2025-03-02"), day("2026-03-02")]

        #expect(resolver.timelineCadence(for: quarterly) == .quarterly)
        #expect(resolver.timelineCadence(for: annual) == .annual)
    }

    /// Each charge takes a projection of its own, so shopping twice in a day is not a rhythm.
    @Test func timelineRefusesABurstOfSameDayCharges() {
        let burst = [
            day("2026-01-09"), day("2026-01-09"), day("2026-01-09"), day("2026-01-10"),
        ]

        #expect(resolver.timelineCadence(for: burst) == nil)
    }

    /// A subscription and a one-off from the same merchant must not read as one rhythm, or the
    /// grouper never gets to separate them by amount.
    @Test func timelineRefusesASubscriptionMixedWithOneOffPurchases() {
        let mixed = [
            day("2026-01-09"), day("2026-01-12"), day("2026-02-09"), day("2026-03-09"),
        ]

        #expect(resolver.timelineCadence(for: mixed) == nil)
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
        #expect(resolver.timelineCadence(for: noisy) == nil)
    }

    @Test func needsTwoDatesToHaveAnyCadence() {
        #expect(resolver.cadence(for: [day("2026-01-09")]) == nil)
        #expect(resolver.cadence(for: []) == nil)
        #expect(resolver.timelineCadence(for: [day("2026-01-09")]) == nil)
        #expect(resolver.timelineCadence(for: []) == nil)
    }
}
