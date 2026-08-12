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
        repository: any SubscriptionRepository,
        onOutcome: @escaping (SettingsOutcome) -> Void
    ) {
        state = SettingsState(
            currency: currency, language: language, appearance: appearance, textSize: textSize,
            weekStart: weekStart, isCurrencyInferred: isCurrencyInferred,
            fetchesRates: fetchesRates)
        self.repository = repository
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

        case .deleteEverything:
            try? await repository.deleteAll()
            send(.storeCleared)

        case .report(let outcome):
            onOutcome(outcome)
        }
    }
}
