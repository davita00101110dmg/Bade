import Core
import Foundation
import Observation

@MainActor
@Observable
public final class ProViewModel {
    public private(set) var state: ProState

    private let purchases: any ProPurchasing
    private let onOutcome: (ProOutcome) -> Void
    private var work: Task<Void, Never>?

    public init(
        purchases: any ProPurchasing = NoPurchases(),
        isEntitled: Bool = false,
        onOutcome: @escaping (ProOutcome) -> Void = { _ in }
    ) {
        state = ProState(isEntitled: isEntitled)
        self.purchases = purchases
        self.onOutcome = onOutcome
    }

    public func send(_ intent: ProIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    private func run(_ effect: ProEffect) async {
        switch effect {
        case .load:
            send(.loaded(price: await purchases.price(), isEntitled: await purchases.isEntitled()))

        case .buy:
            send(.finished(await purchases.buy()))

        case .restore:
            send(.restored(await purchases.restore()))

        case .report(let outcome):
            onOutcome(outcome)
        }
    }
}
