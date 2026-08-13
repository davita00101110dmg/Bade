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
    /// Asks iOS whether reminders are blocked. A closure, because only the root may touch the
    /// notification centre and the answer is re-read every time the screen comes back.
    private let isReminderDenied: () async -> Bool
    private let onOutcome: (SettingsOutcome) -> Void
    private var work: Task<Void, Never>?

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
        isReminderDenied: @escaping () async -> Bool = { false },
        onOutcome: @escaping (SettingsOutcome) -> Void
    ) {
        state = SettingsState(
            currency: currency, language: language, appearance: appearance, textSize: textSize,
            weekStart: weekStart, isCurrencyInferred: isCurrencyInferred,
            fetchesRates: fetchesRates, isPro: isPro, reminder: reminder)
        self.repository = repository
        self.isReminderDenied = isReminderDenied
        self.onOutcome = onOutcome
    }

    public func send(_ intent: SettingsIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: SettingsEffect) async {
        switch effect {
        case .load:
            send(.loaded((try? await repository.all()) ?? []))
            send(.reminderAuthorizationChecked(await isReminderDenied()))

        case .deleteEverything:
            try? await repository.deleteAll()
            send(.storeCleared)

        case .report(let outcome):
            onOutcome(outcome)
        }
    }
}
