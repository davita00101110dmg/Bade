import Core
import Foundation
import Observation

@MainActor
@Observable
public final class SubscriptionFormViewModel {
    public private(set) var state: SubscriptionFormState

    private let repository: any SubscriptionRepository
    private let merchants: any MerchantSuggesting
    private let onOutcome: (FormOutcome) -> Void
    private var work: Task<Void, Never>?

    public init(
        editing subscription: Subscription?,
        currency: String,
        knownCurrencies: [String],
        repository: any SubscriptionRepository,
        merchants: any MerchantSuggesting,
        onOutcome: @escaping (FormOutcome) -> Void
    ) {
        state = SubscriptionFormState(
            editing: subscription, currency: currency, knownCurrencies: knownCurrencies)
        self.repository = repository
        self.merchants = merchants
        self.onOutcome = onOutcome
    }

    public func send(_ intent: SubscriptionFormIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: SubscriptionFormEffect) async {
        switch effect {
        case .suggest(let text):
            send(.suggestionsLoaded(merchants.suggestedMerchants(matching: text)))

        case .save(let subscription):
            try? await repository.save(subscription)
            send(.saved(subscription))

        case .exit(let outcome):
            onOutcome(outcome)
        }
    }
}
