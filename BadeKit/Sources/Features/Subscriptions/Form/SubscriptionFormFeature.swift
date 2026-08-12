import Core
import Foundation

/// One form, two jobs: a blank one creates a subscription, a filled one amends the subscription it
/// was opened with.
public struct SubscriptionFormState: Equatable {
    /// The subscription being amended, or `nil` when this one is new.
    public let original: Subscription?
    /// Offered above the full currency list, because these are the ones already being charged.
    public let knownCurrencies: [String]
    public private(set) var draft: SubscriptionDraft
    public private(set) var suggestions: [String] = []
    public private(set) var isConfirmingDiscard = false

    private let initial: SubscriptionDraft
    private let today: Date
    private let calendar: Calendar
    /// Until a date is chosen by hand it follows the cadence, so switching to yearly does not
    /// leave the next charge a month away.
    private var isDateChosen: Bool

    public init(
        editing subscription: Subscription?,
        currency: String,
        knownCurrencies: [String] = [],
        today: Date = .now,
        calendar: Calendar = .current
    ) {
        original = subscription
        draft =
            subscription.map(SubscriptionDraft.init)
            ?? SubscriptionDraft(currency: currency, today: today, calendar: calendar)
        initial = draft
        isDateChosen = subscription != nil
        self.today = today
        self.calendar = calendar
        var seen: Set<String> = []
        self.knownCurrencies = ([currency] + knownCurrencies + [draft.currency]).filter {
            seen.insert($0).inserted
        }
    }

    public var isNew: Bool { original == nil }
    public var hasChanges: Bool { draft != initial }
    public var canSave: Bool { result != nil }

    private var amount: Decimal? { DecimalInput.parse(draft.amount) }
    private var merchant: String { draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// What Save writes, or `nil` while the form is not yet a subscription.
    public var result: Subscription? {
        guard let amount, !merchant.isEmpty else { return nil }
        guard let original else { return created(amount) }
        return amended(original, amount: amount)
    }

    private func created(_ amount: Decimal) -> Subscription {
        Subscription(
            merchant: merchant, amount: amount, currency: draft.currency, cadence: draft.cadence,
            firstChargeDate: previousCharge, lastChargeDate: previousCharge,
            nextChargeDate: draft.nextChargeDate, isActive: draft.isActive,
            confidence: .confident)
    }

    private func amended(_ original: Subscription, amount: Decimal) -> Subscription {
        var subscription = original
        subscription.merchant = merchant
        subscription.amount = amount
        subscription.currency = draft.currency
        subscription.cadence = draft.cadence
        subscription.nextChargeDate = draft.nextChargeDate
        subscription.isActive = draft.isActive
        // Charges are the only thing that can date a subscription honestly. With none, the dates
        // follow the rhythm instead; with some, they are history and the form must not move them.
        if subscription.charges.isEmpty {
            subscription.firstChargeDate = previousCharge
            subscription.lastChargeDate = previousCharge
        }
        return subscription
    }

    /// Where the rhythm says the last charge fell. Not a charge anyone claims happened — it is the
    /// date the FX lookup converts at, and today's rate is the wrong one for a yearly bill.
    private var previousCharge: Date {
        draft.cadence.charge(before: draft.nextChargeDate, in: calendar)
    }
}

public enum SubscriptionFormIntent: Equatable {
    case merchantChanged(String)
    case suggestionsLoaded([String])
    case suggestionTapped(String)
    case amountChanged(String)
    case currencyChanged(String)
    case cadenceChanged(Cadence)
    case nextChargeDateChanged(Date)
    case activeChanged(Bool)
    case saveTapped
    case saved(Subscription)
    case cancelTapped
    case discardConfirmed
    case discardDismissed
}

public enum SubscriptionFormEffect: Equatable {
    case suggest(String)
    case save(Subscription)
    case exit(FormOutcome)
}

extension SubscriptionFormState {
    public mutating func apply(_ intent: SubscriptionFormIntent) -> SubscriptionFormEffect? {
        switch intent {
        case .merchantChanged(let merchant):
            draft.merchant = merchant
            return .suggest(merchant)

        case .suggestionsLoaded(let suggestions):
            self.suggestions = suggestions
            return nil

        case .suggestionTapped(let merchant):
            draft.merchant = merchant
            suggestions = []
            return nil

        case .amountChanged(let amount):
            draft.amount = amount
            return nil

        case .currencyChanged(let currency):
            draft.currency = currency
            return nil

        case .cadenceChanged(let cadence):
            draft.cadence = cadence
            if !isDateChosen { draft.nextChargeDate = cadence.charge(after: today, in: calendar) }
            return nil

        case .nextChargeDateChanged(let date):
            draft.nextChargeDate = date
            isDateChosen = true
            return nil

        case .activeChanged(let isActive):
            draft.isActive = isActive
            return nil

        case .saveTapped:
            return result.map(SubscriptionFormEffect.save)

        case .saved(let subscription):
            return .exit(.saved(subscription))

        // Leaving with nothing typed is not a decision worth interrupting.
        case .cancelTapped:
            guard hasChanges else { return .exit(.cancelled) }
            isConfirmingDiscard = true
            return nil

        case .discardConfirmed:
            isConfirmingDiscard = false
            return .exit(.cancelled)

        case .discardDismissed:
            isConfirmingDiscard = false
            return nil
        }
    }
}
