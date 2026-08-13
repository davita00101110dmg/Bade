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
        Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: ReviewEffect) async {
        switch effect {
        case .save(let detected):
            do {
                // Counted either side of the save: every confirmation either becomes a row or
                // merges into one, so the difference is exactly what was new.
                let before = try await repository.all().count
                let after = try await repository.confirm(detected).count
                // Kept whatever the user chose: a rate outlives the charge that revealed it.
                try await rateRepository.record(state.rates)
                send(.saved(addedCount: after - before))
            } catch {
                send(.saveFailed)
            }

        case .exit(let outcome):
            onOutcome(outcome)
        }
    }
}
