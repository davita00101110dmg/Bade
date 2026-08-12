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
    /// Nothing is stored any more, so the root belongs back on Welcome.
    case dataCleared
}
