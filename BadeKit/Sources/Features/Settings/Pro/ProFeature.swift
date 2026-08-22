import Core
import Foundation

public struct ProState: Equatable {
    /// Formatted by the store, or `nil` while it is being fetched — or if it cannot be reached.
    public private(set) var price: String?
    public private(set) var isEntitled: Bool
    public private(set) var isWorking = false
    public private(set) var hasFailed = false
    /// A restore that found nothing: not a failure, but it has to say something.
    public private(set) var foundNothingToRestore = false

    public init(isEntitled: Bool = false) {
        self.isEntitled = isEntitled
    }

    /// The store has answered and said no price: offering a button that cannot name a price is
    /// worse than saying the store is unreachable.
    public var isStoreUnavailable: Bool { price == nil && !isWorking && !isEntitled }
}

public enum ProIntent: Equatable {
    case appeared
    case loaded(price: String?, isEntitled: Bool)
    case buyTapped
    case restoreTapped
    case finished(ProPurchaseResult)
    case restored(Bool)
    case dismissed
    case upcomingTapped
}

public enum ProEffect: Equatable {
    case load
    case buy
    case restore
    case report(ProOutcome)
}

extension ProState {
    public mutating func apply(_ intent: ProIntent) -> ProEffect? {
        switch intent {
        case .appeared:
            isWorking = true
            return .load

        case .loaded(let price, let isEntitled):
            self.price = price
            self.isEntitled = isEntitled
            isWorking = false
            return nil

        case .buyTapped:
            guard !isWorking, !isEntitled else { return nil }
            isWorking = true
            hasFailed = false
            foundNothingToRestore = false
            return .buy

        case .restoreTapped:
            guard !isWorking else { return nil }
            isWorking = true
            hasFailed = false
            foundNothingToRestore = false
            return .restore

        case .finished(let result):
            isWorking = false
            switch result {
            case .bought:
                isEntitled = true
                return .report(.unlocked)
            // Changing your mind is not an error, and nothing should be said about it.
            case .cancelled:
                return nil
            case .failed:
                hasFailed = true
                return nil
            }

        case .restored(let found):
            isWorking = false
            isEntitled = found
            foundNothingToRestore = !found
            return found ? .report(.unlocked) : nil

        case .dismissed:
            return .report(.closed)

        case .upcomingTapped:
            return .report(.showUpcoming)
        }
    }
}
