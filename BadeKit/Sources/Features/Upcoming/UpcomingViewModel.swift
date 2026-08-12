import Core
import Foundation
import Observation

@MainActor
@Observable
public final class UpcomingViewModel {
    public private(set) var state: UpcomingState

    private let repository: any SubscriptionRepository
    private let rates: @Sendable () async -> RateBook
    private var work: Task<Void, Never>?

    public init(
        currency: String,
        calendar: Calendar = .current,
        repository: any SubscriptionRepository,
        rates: @escaping @Sendable () async -> RateBook
    ) {
        state = UpcomingState(currency: currency, calendar: calendar)
        self.repository = repository
        self.rates = rates
    }

    public func send(_ intent: UpcomingIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: UpcomingEffect) async {
        switch effect {
        case .load:
            do {
                send(.loaded(try await repository.all(), await rates()))
            } catch {
                send(.loadFailed)
            }
        }
    }
}
