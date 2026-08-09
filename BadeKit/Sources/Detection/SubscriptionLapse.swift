import Core
import Foundation

/// A subscription whose charges simply stopped. Spec §7.7 computes the next charge date but never
/// asks whether it already came and went, so a service cancelled mid-statement was still reported
/// as live and counted in the monthly total.
///
/// Judged against the end of the statement, never against today: past the last transaction there
/// is no evidence either way, and inventing some would report cancellations that may not exist.
enum SubscriptionLapse {
    /// Half a cycle of slack. Enough to absorb a charge that posted late or shifted off a weekend,
    /// not enough to carry a cancelled subscription for months. The test is cadence-relative
    /// because a flat window would call every annual subscription dead.
    private static let graceDivisor = 2

    static func hasLapsed(since lastCharge: Date, cadence: Cadence, statementEnd: Date) -> Bool {
        let expected = ChargeCalendar.date(after: lastCharge, cadence: cadence)
        let cycle = ChargeCalendar.days(from: lastCharge, to: expected)
        return ChargeCalendar.days(from: expected, to: statementEnd) > cycle / graceDivisor
    }
}
