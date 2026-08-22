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
    /// Bought, restored, redeemed — or refunded. The root holds the entitlement everything gated
    /// reads, so it has to hear both answers: reporting only the yes left a revoked purchase
    /// unlocking the app until the next launch.
    case proChanged(Bool)
    /// Tapped on the owned Pro page. Only the root can change tabs, and ProView is reached from
    /// here as often as from the root, so it has to travel both ways.
    case showUpcoming
    /// Nothing is stored any more, so the root belongs back on Welcome.
    case dataCleared
}
