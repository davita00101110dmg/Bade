import Core
import Foundation
import Observation

@MainActor
@Observable
public final class SubscriptionsViewModel {
    public private(set) var state: SubscriptionsState

    private let repository: any SubscriptionRepository
    private let rates: @Sendable () async -> RateBook
    private let onOutcome: (SubscriptionsOutcome) -> Void
    private var work: Task<Void, Never>?

    public init(
        currency: String,
        repository: any SubscriptionRepository,
        rates: @escaping @Sendable () async -> RateBook,
        onOutcome: @escaping (SubscriptionsOutcome) -> Void
    ) {
        state = SubscriptionsState(currency: currency)
        self.repository = repository
        self.rates = rates
        self.onOutcome = onOutcome
    }

    /// Detail belongs to this feature, so this is where it is composed. Anything it changes makes
    /// the list behind it stale, which is why every outcome reloads.
    public func detail(for subscription: Subscription) -> SubscriptionDetailViewModel {
        SubscriptionDetailViewModel(
            subscription: subscription, currency: state.currency, rates: state.rates,
            repository: repository,
            onOutcome: { [weak self] _ in self?.send(.appeared) })
    }

    public func send(_ intent: SubscriptionsIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: SubscriptionsEffect) async {
        switch effect {
        case .load:
            do {
                send(.loaded(try await repository.all(), await rates()))
            } catch {
                send(.loadFailed)
            }

        case .save(let subscription):
            try? await repository.save(subscription)
            send(.storeChanged)

        case .delete(let id):
            try? await repository.delete(id: id)
            send(.storeChanged)

        case .deleteEverything:
            try? await repository.deleteAll()
            send(.storeChanged)

        case .exit(let outcome):
            onOutcome(outcome)
        }
    }
}
