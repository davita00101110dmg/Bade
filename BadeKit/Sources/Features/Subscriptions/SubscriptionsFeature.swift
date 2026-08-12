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
    public private(set) var edit: SubscriptionEdit?

    public init(currency: String) {
        self.currency = currency
    }

    /// Cancelled subscriptions are not spend. The total and the live list agree by construction.
    private var active: [Subscription] { all.filter(\.isActive) }

    public var rows: [SubscriptionRow] { sorted(active) }

    /// Still listed, deliberately. Cancelling something must look different from deleting it, and
    /// a screen that empties itself when everything is cancelled explains nothing.
    public var cancelledRows: [SubscriptionRow] { sorted(all.filter { !$0.isActive }) }

    private func sorted(_ subscriptions: [Subscription]) -> [SubscriptionRow] {
        let rows = subscriptions.map {
            SubscriptionRow(subscription: $0, converted: monthly(of: $0))
        }
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

    /// Currencies already being charged, offered before the full ISO list when one is picked.
    public var knownCurrencies: [String] {
        var seen: Set<String> = []
        return all.map(\.currency).filter { seen.insert($0).inserted }
    }

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
    case addTapped
    case editTapped(Subscription)
    case formFinished(FormOutcome)
    case activeToggled(Subscription)
    case deleteTapped(Subscription)
    case deleteAllRequested
    case deleteAllConfirmed
    case confirmationDismissed
    case storeChanged
}

public enum SubscriptionsEffect: Equatable {
    case load
    case save(Subscription)
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
            // An empty store means Welcome again — but a cancelled subscription is still data.
            return subscriptions.isEmpty ? .exit(.dataCleared) : nil

        case .loadFailed:
            phase = .failed
            return nil

        case .sortChanged(let sort):
            self.sort = sort
            return nil

        case .importTapped:
            return .exit(.importStatement)

        case .addTapped:
            edit = SubscriptionEdit(nil)
            return nil

        case .editTapped(let subscription):
            edit = SubscriptionEdit(subscription)
            return nil

        // The form has already written to the store, so all that is left is to catch up with it.
        case .formFinished(let outcome):
            edit = nil
            return outcome == .cancelled ? nil : .load

        case .activeToggled(let subscription):
            var updated = subscription
            updated.isActive.toggle()
            return .save(updated)

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

        case .storeChanged:
            return .load
        }
    }
}
