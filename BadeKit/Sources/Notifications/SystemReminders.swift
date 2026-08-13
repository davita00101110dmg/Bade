import Core
import Foundation
import UserNotifications

/// What iOS has been told about reminders. `notDetermined` is the only state a prompt can change.
public enum ReminderAuthorization: Sendable {
    case notDetermined, allowed, denied
}

/// The only place in Bade that talks to the notification centre. Everything above it deals in
/// `ChargeReminder`s, which are plain values a test can hold.
public struct SystemReminders: Sendable {
    /// Bade's chime, a rising fifth. It sits at the root of the app bundle because
    /// `UNNotificationSound` looks there and nowhere else — a package's resource bundle is
    /// invisible to it.
    private static let chimeFile = "bade-chime-rise.wav"

    /// Fetched per call rather than stored: the centre is a singleton and is not `Sendable`.
    private var center: UNUserNotificationCenter { .current() }

    /// Falls back to iOS's own sound rather than to silence, so a file that never made it into the
    /// bundle sounds wrong instead of looking like a broken notification.
    private var chime: UNNotificationSound {
        guard Bundle.main.url(forResource: Self.chimeFile, withExtension: nil) != nil else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(Self.chimeFile))
    }

    public init() {}

    public func authorization() async -> ReminderAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    /// iOS only ever prompts once; every call after that reports the answer it already has.
    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Replaces the schedule wholesale rather than reconciling it: the plan is cheap to recompute
    /// and a partial update is how a reminder for a deleted subscription survives.
    public func replace(with reminders: [ChargeReminder], in locale: Locale) async {
        center.removeAllPendingNotificationRequests()
        guard await authorization() == .allowed else { return }

        let text = ReminderText(locale: locale)
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = text.title(for: reminder)
            content.body = text.body(for: reminder)
            content.sound = chime
            do {
                try await center.add(
                    UNNotificationRequest(
                        identifier: reminder.id, content: content,
                        trigger: trigger(at: reminder.fireDate)))
            } catch {
                // One rejected reminder is not a reason to abandon the rest of the schedule.
                continue
            }
        }
    }

    /// Calendar components rather than an interval, so a reminder still lands at the right local
    /// hour after the clocks change or the phone crosses a time zone.
    private func trigger(at date: Date) -> UNCalendarNotificationTrigger {
        UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date),
            repeats: false)
    }
}
