import Core
import Foundation
import Localization

/// `Core` has no localisation, so a lead is named here — the same arrangement `Cadence` has.
extension ReminderLead {
    public var localizedName: LocalizedStringResource {
        switch self {
        case .off: .settings.reminderOff
        case .sameDay: .settings.reminderSameDay
        case .oneDay: .settings.reminderOneDay
        case .twoDays: .settings.reminderTwoDays
        case .threeDays: .settings.reminderThreeDays
        }
    }
}
