import Foundation
import UserNotifications

/// Notification taps, as days. A reminder names a charge that is coming; opening the app on any
/// other screen than that day would waste the tap.
///
/// The one object in this module that is not a value: iOS wants a delegate, and it holds that
/// delegate weakly — so whoever listens has to keep this alive.
public final class ReminderTaps: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    /// The charge day, seconds since 1970, carried on the notification so a tap knows where to go.
    static let dayKey = "bade.chargeDay"

    private let stream: AsyncStream<Date>
    private let continuation: AsyncStream<Date>.Continuation

    /// Both stored properties are immutable and `Sendable`; the unchecked conformance is only
    /// because `NSObject` cannot promise it.
    public override init() {
        (stream, continuation) = AsyncStream.makeStream()
        super.init()
    }

    /// Every day a person has tapped a reminder for. Consumed once, by the composition root.
    public var days: AsyncStream<Date> { stream }

    public func startListening() {
        UNUserNotificationCenter.current().delegate = self
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        guard
            let seconds = response.notification.request.content.userInfo[Self.dayKey] as? Double
        else { return }
        continuation.yield(Date(timeIntervalSince1970: seconds))
    }
}
