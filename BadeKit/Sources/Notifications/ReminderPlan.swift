import Core
import Foundation

/// Works out what to schedule. Pure: dates in, reminders out, no notification centre in sight —
/// which is what makes the date arithmetic testable, and the date arithmetic is the whole risk.
public enum ReminderPlan {
    /// iOS keeps the 64 soonest pending notifications and silently drops the rest, so the cap is
    /// applied here where it can be reasoned about.
    public static let limit = 64
    /// How far ahead to project — far enough that the cap is what runs out rather than this.
    ///
    /// It used to be a year, on the assumption that a year always overflowed the cap. It does not:
    /// one monthly subscription filled 12 of the 64 slots and a single annual one filled 1, so
    /// reminders stopped a year out with most of the cap unspent — and an annual-only subscriber
    /// got one reminder and then silence. Three years is where anyone with two or more
    /// subscriptions spends the whole cap, which is the most iOS will hold either way.
    public static let horizonYears = 3

    public static func reminders(
        for subscriptions: [Subscription],
        preference: ReminderPreference,
        from now: Date,
        calendar: Calendar = .current
    ) -> [ChargeReminder] {
        guard preference.isOn else { return [] }
        let today = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .year, value: horizonYears, to: today) else {
            return []
        }

        let charges = subscriptions.upcomingCharges(
            from: today, before: end, today: now, calendar: calendar)

        return Dictionary(grouping: charges) { calendar.startOfDay(for: $0.date) }
            .compactMap { reminder(on: $0.key, for: $0.value, preference, now, calendar) }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(limit)
            .map { $0 }
    }

    /// A reminder whose moment has already passed is not scheduled: iOS would fire it immediately,
    /// announcing a charge as upcoming on the morning it has already landed.
    private static func reminder(
        on day: Date,
        for charges: [UpcomingCharge],
        _ preference: ReminderPreference,
        _ now: Date,
        _ calendar: Calendar
    ) -> ChargeReminder? {
        guard
            let announcementDay = calendar.date(
                byAdding: .day, value: -preference.lead.days, to: day),
            let fireDate = calendar.date(
                bySettingHour: preference.hour, minute: preference.minute, second: 0,
                of: announcementDay),
            fireDate > now
        else { return nil }

        return ChargeReminder(
            chargeDate: day, fireDate: fireDate, daysAhead: preference.lead.days,
            charges: charges.sorted { $0.subscription.merchant < $1.subscription.merchant })
    }
}
