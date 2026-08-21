import Core
import Foundation
import Localization

/// What a reminder actually says, in the language the app is set to rather than the one the phone
/// is in — the two disagree the moment someone picks Georgian in Settings on an English phone.
struct ReminderText {
    let locale: Locale

    func title(for reminder: ChargeReminder) -> String {
        "\(ReminderMark.mark(for: reminder)) \(resolved(titleResource(for: reminder)))"
    }

    /// The title says when and nothing else. Lead decides how: the day itself, the day before, or a
    /// weekday by name — never ambiguous within the three days a lead can reach.
    ///
    /// Kept apart from resolving it, because which line gets picked is the decision worth a test —
    /// and no string resolves against the catalog outside an app bundle.
    func titleResource(for reminder: ChargeReminder) -> LocalizedStringResource {
        let strings = LocalizedStringResource.reminder
        switch reminder.daysAhead {
        case 0: return strings.today
        case 1: return strings.tomorrow
        default: return strings.onDay(weekday(of: reminder))
        }
    }

    /// What is charging and for how much — the two things worth reading. The total is only shown
    /// when the day's charges share a currency; summing across two would need a rate the reminder
    /// has no business inventing.
    func body(for reminder: ChargeReminder) -> String {
        let merchants = reminder.merchants.formatted(.list(type: .and).locale(locale))
        guard let total = reminder.total else { return merchants }
        let money = total.amount.formatted(.badeMoney(total.currency).locale(locale))
        return merchants + resolved(.subscriptions.separator) + money
    }

    private func weekday(of reminder: ChargeReminder) -> String {
        reminder.chargeDate.formatted(.dateTime.weekday(.wide).locale(locale))
    }

    private func resolved(_ resource: LocalizedStringResource) -> String {
        .badeLocalized(resource, in: locale)
    }
}
