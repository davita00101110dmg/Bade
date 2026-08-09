import Core
import Foundation
import Observation

@MainActor
@Observable
public final class ReviewViewModel {
    public private(set) var state: ReviewState

    private let repository: any SubscriptionRepository
    private let rateRepository: any RateRepository
    private let onOutcome: (ReviewOutcome) -> Void
    private var work: Task<Void, Never>?

    public init(
        detected: [DetectedSubscription],
        rates: RateBook,
        currency: String,
        repository: any SubscriptionRepository,
        rateRepository: any RateRepository,
        onOutcome: @escaping (ReviewOutcome) -> Void
    ) {
        state = ReviewState(detected: detected, rates: rates, currency: currency)
        self.repository = repository
        self.rateRepository = rateRepository
        self.onOutcome = onOutcome
    }

    public func send(_ intent: ReviewIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: ReviewEffect) async {
        switch effect {
        case .save(let detected):
            do {
                try await repository.confirm(detected)
                // Kept whatever the user chose: a rate outlives the charge that revealed it.
                try await rateRepository.record(state.rates)
                send(.saved)
            } catch {
                send(.saveFailed)
            }

        case .exit(let outcome):
            onOutcome(outcome)
        }
    }
}
