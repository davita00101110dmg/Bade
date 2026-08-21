import Foundation

/// The emoji a reminder opens with. Deliberately not in the string catalog: an emoji reads the same
/// in every language, so there is no decision here for a translator to make.
///
/// Picked from the reminder's own id, which is stable across rescheduling — a notification already
/// waiting on a phone keeps its face when the schedule is recomputed, and two reminders on the same
/// morning do not arrive looking identical.
enum ReminderMark {
    static let pool = ["🚨", "⏰", "💳", "🔔", "💸", "📅"]

    static func mark(for reminder: ChargeReminder) -> String {
        pool[fingerprint(of: reminder.id) % pool.count]
    }

    /// Swift's own hashing is seeded per process, so the same reminder would take a different mark
    /// on every launch. This one does not move.
    private static func fingerprint(of id: String) -> Int {
        id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 1_000_003 }
    }
}
