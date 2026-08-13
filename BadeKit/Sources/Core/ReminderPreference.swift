import Foundation

/// How far ahead of a charge a reminder goes out. `off` is a lead like any other, so nothing has
/// to carry a separate switch alongside it.
public enum ReminderLead: String, CaseIterable, Sendable, Identifiable, Codable {
    case off, sameDay, oneDay, twoDays, threeDays

    public var id: String { rawValue }

    public var isOn: Bool { self != .off }

    /// Days before the charge. `off` never reaches arithmetic, and answering 0 keeps it total.
    public var days: Int {
        switch self {
        case .off, .sameDay: 0
        case .oneDay: 1
        case .twoDays: 2
        case .threeDays: 3
        }
    }
}

/// When reminders go out: how many days ahead, and at what time of day.
public struct ReminderPreference: Equatable, Sendable {
    public var lead: ReminderLead
    /// Minutes after local midnight, so there is no way to hold an hour without a minute.
    public var timeOfDay: Int

    /// Early enough to act on before the day is spent, late enough not to be an alarm.
    public static let defaultTimeOfDay = 9 * 60

    public init(lead: ReminderLead = .off, timeOfDay: Int = ReminderPreference.defaultTimeOfDay) {
        self.lead = lead
        self.timeOfDay = timeOfDay
    }

    public var hour: Int { timeOfDay / 60 }
    public var minute: Int { timeOfDay % 60 }

    public var isOn: Bool { lead.isOn }
}
