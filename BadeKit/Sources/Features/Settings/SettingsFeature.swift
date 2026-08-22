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
    /// The only network Bade has. Off means the markup falls back to what statements printed.
    public private(set) var fetchesRates: Bool
    /// Reminders are behind the purchase, so the row that sets them leads to the pitch instead.
    /// Re-read whenever the screen comes back: it can be bought from the page this screen pushes.
    public private(set) var isPro: Bool
    public private(set) var reminder: ReminderPreference
    /// iOS has been asked and said no. Nothing in the app can undo that, so it has to be said.
    /// Re-read rather than injected once: it can change in iOS Settings while Bade is not looking.
    public private(set) var isReminderDenied: Bool
    /// Loaded so an export can be built the moment it is asked for; a share sheet cannot wait.
    public private(set) var subscriptions: [Subscription] = []
    public private(set) var isConfirmingDeleteAll = false

    public init(
        currency: String,
        language: BadeLanguage,
        appearance: BadeAppearance = .system,
        textSize: BadeTextSize = .system,
        weekStart: BadeWeekStart = .system,
        isCurrencyInferred: Bool = false,
        fetchesRates: Bool = true,
        isPro: Bool = false,
        reminder: ReminderPreference = ReminderPreference(),
        isReminderDenied: Bool = false
    ) {
        self.isPro = isPro
        self.currency = currency
        self.language = language
        self.appearance = appearance
        self.textSize = textSize
        self.weekStart = weekStart
        self.isCurrencyInferred = isCurrencyInferred
        self.fetchesRates = fetchesRates
        self.reminder = reminder
        self.isReminderDenied = isReminderDenied
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
    case rateFetchingChanged(Bool)
    case reminderLeadChanged(ReminderLead)
    case reminderTimeChanged(Int)
    case reminderAuthorizationChecked(Bool)
    case proChecked(Bool)
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

        case .rateFetchingChanged(let fetches):
            guard fetches != fetchesRates else { return nil }
            fetchesRates = fetches
            return .report(.rateFetchingChanged(fetches))

        case .reminderLeadChanged(let lead):
            guard lead != reminder.lead else { return nil }
            reminder.lead = lead
            return .report(.reminderLeadChanged(lead))

        case .reminderTimeChanged(let minutes):
            guard minutes != reminder.timeOfDay else { return nil }
            reminder.timeOfDay = minutes
            return .report(.reminderTimeChanged(minutes))

        case .reminderAuthorizationChecked(let isDenied):
            isReminderDenied = isDenied
            return nil

        /// Bought on the page this screen pushes, redeemed with a promo code somewhere else
        /// entirely, or revoked by a refund. Either direction has to reach the root, since it owns
        /// everything that is gated and this screen is where the entitlement is re-read.
        case .proChecked(let isPro):
            guard isPro != self.isPro else { return nil }
            self.isPro = isPro
            return .report(.proChanged(isPro))

        case .deleteAllRequested:
            isConfirmingDeleteAll = true
            return nil

        case .deleteAllConfirmed:
            isConfirmingDeleteAll = false
            return .deleteEverything

        case .confirmationDismissed:
            isConfirmingDeleteAll = false
            return nil

        // Deliberately keeps what it was showing. The root is already on its way to Welcome, and
        // emptying this state first made the whole data section vanish out from under the reader
        // a moment before the screen it belonged to did.
        case .storeCleared:
            return .report(.dataCleared)
        }
    }
}
