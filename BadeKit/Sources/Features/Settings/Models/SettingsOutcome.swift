import Core
import DesignSystem
import Localization

/// Every way this screen hands control back, so the parent handles them in one exhaustive place.
/// Settings changes what the whole app shows, and only the composition root can store that.
public enum SettingsOutcome: Equatable, Sendable {
    case currencyChanged(String)
    case languageChanged(BadeLanguage)
    case appearanceChanged(BadeAppearance)
    case textSizeChanged(BadeTextSize)
    case weekStartChanged(BadeWeekStart)
    case rateFetchingChanged(Bool)
    /// Both reschedule what iOS is holding, which only the root can do.
    case reminderLeadChanged(ReminderLead)
    case reminderTimeChanged(Int)
    /// Bought, or restored, or redeemed. The root holds the entitlement everything gated reads.
    case proUnlocked
    /// Nothing is stored any more, so the root belongs back on Welcome.
    case dataCleared
}
