import Core
import Foundation
import Observation

@MainActor
@Observable
public final class SubscriptionDetailViewModel {
    public private(set) var state: SubscriptionDetailState

    private let repository: any SubscriptionRepository
    private let merchants: any MerchantSuggesting
    private let onOutcome: (DetailOutcome) -> Void
    private var work: Task<Void, Never>?

    public init(
        subscription: Subscription,
        currency: String,
        rates: RateBook,
        repository: any SubscriptionRepository,
        merchants: any MerchantSuggesting = NoMerchantSuggestions(),
        onOutcome: @escaping (DetailOutcome) -> Void
    ) {
        state = SubscriptionDetailState(
            subscription: subscription, currency: currency, rates: rates)
        self.repository = repository
        self.merchants = merchants
        self.onOutcome = onOutcome
    }

    /// Editing from here presents the same form the list does, filled in with this subscription.
    public func form() -> SubscriptionFormViewModel {
        SubscriptionFormViewModel(
            editing: state.subscription, currency: state.currency,
            knownCurrencies: [state.subscription.currency], repository: repository,
            merchants: merchants,
            onOutcome: { [weak self] outcome in self?.send(.formFinished(outcome)) })
    }

    public func send(_ intent: SubscriptionDetailIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: SubscriptionDetailEffect) async {
        switch effect {
        case .save(let subscription):
            try? await repository.save(subscription)
            send(.saved(subscription))

        case .delete(let id):
            try? await repository.delete(id: id)
            send(.deletionFinished)

        case .exit(let outcome):
            onOutcome(outcome)
        }
    }
}
