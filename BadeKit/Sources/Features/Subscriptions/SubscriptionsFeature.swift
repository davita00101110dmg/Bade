import Core
import Foundation

public struct SubscriptionsState: Equatable {
    public enum Phase: Equatable {
        case loading
        case ready
        case failed
    }

    /// What totals are shown in. Supplied by the composition root until Settings owns it (§10).
    public let currency: String
    public private(set) var phase: Phase = .loading
    public private(set) var all: [Subscription] = []
    public private(set) var rates = RateBook()
    public private(set) var sort: SubscriptionSort = .cost
    /// Clearing everything is asked about; deleting one row is not. A swipe is already a
    /// deliberate act, and interrupting it with a modal makes the row spring shut underneath.
    public private(set) var isConfirmingDeleteAll = false

    public init(currency: String) {
        self.currency = currency
    }

    /// Cancelled subscriptions are not spend. The total and the list agree by construction.
    private var active: [Subscription] { all.filter(\.isActive) }

    public var rows: [SubscriptionRow] {
        let rows = active.map { SubscriptionRow(subscription: $0, converted: monthly(of: $0)) }
        switch sort {
        case .cost: return rows.sorted { $0.sortableMonthly > $1.sortableMonthly }
        case .name: return rows.sorted { $0.subscription.merchant < $1.subscription.merchant }
        case .nextCharge:
            return rows.sorted { $0.subscription.nextChargeDate < $1.subscription.nextChargeDate }
        }
    }

    public var monthlyTotal: Decimal { active.monthlyTotal(in: currency, rates: rates).total }

    /// Reported rather than dropped: a subscription nobody can convert must still be visible (§7).
    public var unconvertibleCount: Int {
        active.monthlyTotal(in: currency, rates: rates).unconvertible.count
    }

    public var annualTotal: Decimal { monthlyTotal * 12 }
    public var count: Int { active.count }
    public var isEmpty: Bool { phase == .ready && active.isEmpty }

    private func monthly(of subscription: Subscription) -> Decimal? {
        rates.convert(
            subscription.monthlyAmount, from: subscription.currency, to: currency,
            on: subscription.lastChargeDate)
    }
}

public enum SubscriptionsIntent: Equatable {
    case appeared
    case loaded([Subscription], RateBook)
    case loadFailed
    case sortChanged(SubscriptionSort)
    case importTapped
    case deleteTapped(Subscription)
    case deleteAllRequested
    case deleteAllConfirmed
    case confirmationDismissed
    case deletionFinished
}

public enum SubscriptionsEffect: Equatable {
    case load
    case delete(UUID)
    case deleteEverything
    case exit(SubscriptionsOutcome)
}

extension SubscriptionsState {
    public mutating func apply(_ intent: SubscriptionsIntent) -> SubscriptionsEffect? {
        switch intent {
        case .appeared:
            return .load

        case .loaded(let subscriptions, let rates):
            all = subscriptions
            self.rates = rates
            phase = .ready
            // An empty store means Welcome again: this screen is only ever shown over data.
            return subscriptions.isEmpty ? .exit(.dataCleared) : nil

        case .loadFailed:
            phase = .failed
            return nil

        case .sortChanged(let sort):
            self.sort = sort
            return nil

        case .importTapped:
            return .exit(.importStatement)

        case .deleteTapped(let subscription):
            return .delete(subscription.id)

        case .deleteAllRequested:
            isConfirmingDeleteAll = true
            return nil

        case .deleteAllConfirmed:
            isConfirmingDeleteAll = false
            return .deleteEverything

        case .confirmationDismissed:
            isConfirmingDeleteAll = false
            return nil

        case .deletionFinished:
            return .load
        }
    }
}
