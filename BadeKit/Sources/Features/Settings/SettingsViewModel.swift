import Core
import DesignSystem
import Foundation
import Localization
import Observation

@MainActor
@Observable
public final class SettingsViewModel {
    public private(set) var state: SettingsState

    private let repository: any SubscriptionRepository
    /// Only to decide which currencies a total can honestly be shown in. Supplied as a closure for
    /// the same reason Subscriptions takes one: `Persistence` is sealed and no feature may see it.
    private let rates: @Sendable () async -> RateBook
    private let purchases: any ProPurchasing
    /// Asks iOS whether reminders are blocked. A closure, because only the root may touch the
    /// notification centre and the answer is re-read every time the screen comes back.
    private let isReminderDenied: () async -> Bool
    private let onOutcome: (SettingsOutcome) -> Void

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
        repository: any SubscriptionRepository,
        rates: @escaping @Sendable () async -> RateBook = { RateBook() },
        purchases: any ProPurchasing = NoPurchases(),
        isReminderDenied: @escaping () async -> Bool = { false },
        onOutcome: @escaping (SettingsOutcome) -> Void
    ) {
        self.rates = rates
        state = SettingsState(
            currency: currency, language: language, appearance: appearance, textSize: textSize,
            weekStart: weekStart, isCurrencyInferred: isCurrencyInferred,
            fetchesRates: fetchesRates, isPro: isPro, reminder: reminder)
        self.repository = repository
        self.purchases = purchases
        self.isReminderDenied = isReminderDenied
        self.onOutcome = onOutcome
    }

    /// The pitch, opened from here. Buying on it changes what this screen offers, so the answer
    /// comes straight back rather than waiting for the screen to be rebuilt.
    public func pro() -> ProViewModel {
        ProViewModel(purchases: purchases, isEntitled: state.isPro) { [weak self] outcome in
            guard outcome == .unlocked else { return }
            self?.send(.proChecked(true))
        }
    }

    public func send(_ intent: SettingsIntent) {
        guard let effect = state.apply(intent) else { return }
        Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: SettingsEffect) async {
        switch effect {
        case .load:
            send(.loaded((try? await repository.all()) ?? [], await rates()))
            send(.reminderAuthorizationChecked(await isReminderDenied()))
            send(.proChecked(await purchases.isEntitled()))

        case .deleteEverything:
            try? await repository.deleteAll()
            send(.storeCleared)

        case .report(let outcome):
            onOutcome(outcome)
        }
    }
}
