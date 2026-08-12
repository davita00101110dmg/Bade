import Foundation

/// The languages Bade ships in. Overriding the locale rather than the system language keeps the
/// choice inside the app and takes date and money formatting with it.
public enum BadeLanguage: String, CaseIterable, Sendable, Identifiable, Codable {
    case english = "en"
    case georgian = "ka"

    public var id: String { rawValue }
    public var locale: Locale { Locale(identifier: rawValue) }

    /// Each language named in itself, so the row is readable to the person looking for it.
    public var name: LocalizedStringResource {
        switch self {
        case .english: .settings.languageEnglish
        case .georgian: .settings.languageGeorgian
        }
    }

    /// What a first launch picks before anyone has chosen.
    public static var matchingDevice: BadeLanguage {
        Locale.current.language.languageCode?.identifier == georgian.rawValue ? .georgian : .english
    }
}
