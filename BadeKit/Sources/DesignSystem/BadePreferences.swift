import Localization
import SwiftUI

/// Display choices the whole app answers to. They live here rather than in a feature because the
/// composition root applies them above every screen, and Settings is only where they are picked.
///
/// Each defaults to `system`, so the phone stays the source of truth until someone disagrees
/// with it on purpose.
public enum BadeAppearance: String, CaseIterable, Sendable, Identifiable, Codable {
    case system, light, dark

    public var id: String { rawValue }

    /// `nil` hands the choice back to iOS rather than forcing either scheme.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    public var name: LocalizedStringResource {
        switch self {
        case .system: .settings.optionSystem
        case .light: .settings.appearanceLight
        case .dark: .settings.appearanceDark
        }
    }
}

/// An in-app override of Dynamic Type. iOS already offers this per app in its own Settings, so
/// `system` is the default and the honest answer for most people.
public enum BadeTextSize: String, CaseIterable, Sendable, Identifiable, Codable {
    case system, smallest, smaller, standard, larger, largest

    public var id: String { rawValue }

    /// `standard` is iOS's own default size, which is why the scale is centred on it.
    public var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: nil
        case .smallest: .xSmall
        case .smaller: .small
        case .standard: .large
        case .larger: .xLarge
        case .largest: .xxLarge
        }
    }

    public var name: LocalizedStringResource {
        switch self {
        case .system: .settings.optionSystem
        case .smallest: .settings.textSizeSmallest
        case .smaller: .settings.textSizeSmaller
        case .standard: .settings.textSizeStandard
        case .larger: .settings.textSizeLarger
        case .largest: .settings.textSizeLargest
        }
    }

    /// What the slider runs along. `system` is not a size, so it is not a stop on it — it is
    /// where the handle rests until someone moves it.
    public static let scale: [BadeTextSize] = [.smallest, .smaller, .standard, .larger, .largest]
}

/// Which column the calendar starts on. Regions disagree, and occasionally so do people with
/// their own region.
public enum BadeWeekStart: String, CaseIterable, Sendable, Identifiable, Codable {
    case system, monday, sunday

    public var id: String { rawValue }

    public var name: LocalizedStringResource {
        switch self {
        case .system: .settings.optionSystem
        case .monday: .settings.weekStartMonday
        case .sunday: .settings.weekStartSunday
        }
    }

    /// The current calendar, moved to this first day. `system` leaves it exactly as the region
    /// set it, rather than assuming which day that was.
    public var calendar: Calendar {
        var calendar = Calendar.current
        switch self {
        case .system: break
        case .monday: calendar.firstWeekday = 2
        case .sunday: calendar.firstWeekday = 1
        }
        return calendar
    }
}
