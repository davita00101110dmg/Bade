import Core
import DesignSystem
import Foundation
import Localization

public struct SettingsState: Equatable {
    public private(set) var currency: String
    public private(set) var language: BadeLanguage
    public private(set) var appearance: BadeAppearance
    public private(set) var textSize: BadeTextSize
    public private(set) var weekStart: BadeWeekStart
    /// Whether the currency on screen was inferred from the statements rather than chosen.
    public let isCurrencyInferred: Bool
    /// Loaded so an export can be built the moment it is asked for; a share sheet cannot wait.
    public private(set) var subscriptions: [Subscription] = []
    public private(set) var isConfirmingDeleteAll = false

    public init(
        currency: String,
        language: BadeLanguage,
        appearance: BadeAppearance = .system,
        textSize: BadeTextSize = .system,
        weekStart: BadeWeekStart = .system,
        isCurrencyInferred: Bool = false
    ) {
        self.currency = currency
        self.language = language
        self.appearance = appearance
        self.textSize = textSize
        self.weekStart = weekStart
        self.isCurrencyInferred = isCurrencyInferred
    }

    /// Offered above the full list, exactly as the subscription form offers them.
    public var knownCurrencies: [String] {
        var seen: Set<String> = []
        return ([currency] + subscriptions.map(\.currency)).filter { seen.insert($0).inserted }
    }

    public var hasData: Bool { !subscriptions.isEmpty }
}

public enum SettingsIntent: Equatable {
    case appeared
    case loaded([Subscription])
    case currencyChanged(String)
    case languageChanged(BadeLanguage)
    case appearanceChanged(BadeAppearance)
    case textSizeChanged(BadeTextSize)
    case weekStartChanged(BadeWeekStart)
    case deleteAllRequested
    case deleteAllConfirmed
    case confirmationDismissed
    case storeCleared
}

public enum SettingsEffect: Equatable {
    case load
    case deleteEverything
    case report(SettingsOutcome)
}

extension SettingsState {
    public mutating func apply(_ intent: SettingsIntent) -> SettingsEffect? {
        switch intent {
        case .appeared:
            return .load

        case .loaded(let subscriptions):
            self.subscriptions = subscriptions
            return nil

        case .currencyChanged(let currency):
            guard currency != self.currency else { return nil }
            self.currency = currency
            return .report(.currencyChanged(currency))

        case .languageChanged(let language):
            guard language != self.language else { return nil }
            self.language = language
            return .report(.languageChanged(language))

        case .appearanceChanged(let appearance):
            guard appearance != self.appearance else { return nil }
            self.appearance = appearance
            return .report(.appearanceChanged(appearance))

        case .textSizeChanged(let size):
            guard size != textSize else { return nil }
            textSize = size
            return .report(.textSizeChanged(size))

        case .weekStartChanged(let start):
            guard start != weekStart else { return nil }
            weekStart = start
            return .report(.weekStartChanged(start))

        case .deleteAllRequested:
            isConfirmingDeleteAll = true
            return nil

        case .deleteAllConfirmed:
            isConfirmingDeleteAll = false
            return .deleteEverything

        case .confirmationDismissed:
            isConfirmingDeleteAll = false
            return nil

        case .storeCleared:
            subscriptions = []
            return .report(.dataCleared)
        }
    }
}
