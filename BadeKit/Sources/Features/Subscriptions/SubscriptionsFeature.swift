import Core
import Foundation

public struct SubscriptionsState: Equatable {
    public enum Phase: Equatable {
        case loading
        case ready
        case failed
    }

    /// What totals are shown in. Settings owns it, so it changes under a screen that is already
    /// open rather than being fixed when one is built.
    public private(set) var currency: String
    public private(set) var phase: Phase = .loading
    public private(set) var all: [Subscription] = []
    public private(set) var rates = RateBook()
    public private(set) var sort: SubscriptionSort = .cost
    /// Both deletions are asked about now. A swipe is a deliberate act, which was the argument for
    /// not interrupting one — but it is also a *fast* act, and the row it lands on is whichever one
    /// the thumb happened to be over. Deleting the wrong subscription costs a re-import to undo.
    public private(set) var isConfirmingDeleteAll = false
    /// The one row waiting on an answer, rather than a flag, because the alert has to name it.
    public private(set) var pendingDelete: Subscription?
    public private(set) var edit: SubscriptionEdit?
    /// The day "next charge" is answered against. Injected so a test can stand somewhere fixed.
    let today: Date

    public init(currency: String, sort: SubscriptionSort = .cost, today: Date = .now) {
        self.currency = currency
        self.sort = sort
        self.today = today
    }

    /// Cancelled subscriptions are not spend. The total and the live list agree by construction.
    private var active: [Subscription] { all.filter(\.isActive) }

    public var rows: [SubscriptionRow] { sorted(active) }

    /// Still listed, deliberately. Cancelling something must look different from deleting it, and
    /// a screen that empties itself when everything is cancelled explains nothing.
    public var cancelledRows: [SubscriptionRow] { sorted(all.filter { !$0.isActive }) }

    private func sorted(_ subscriptions: [Subscription]) -> [SubscriptionRow] {
        let rows = subscriptions.map {
            SubscriptionRow(
                subscription: $0, converted: monthly(of: $0),
                nextCharge: $0.nextCharge(onOrAfter: today))
        }
        switch sort {
        case .cost: return rows.sorted { $0.sortableMonthly > $1.sortableMonthly }
        case .name: return rows.sorted { $0.subscription.merchant < $1.subscription.merchant }
        case .nextCharge:
            return rows.sorted { $0.nextCharge < $1.nextCharge }
        }
    }

    public var monthlyTotal: Decimal {
        active.monthlyTotal(in: currency, rates: rates, on: today).total
    }

    /// Reported rather than dropped: a subscription nobody can convert must still be visible (§7).
    public var unconvertibleCount: Int {
        active.monthlyTotal(in: currency, rates: rates, on: today).unconvertible.count
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
    case currencyChanged(String)
    case importTapped
    case addTapped
    case editTapped(Subscription)
    case formFinished(FormOutcome)
    case activeToggled(Subscription)
    case deleteTapped(Subscription)
    case deleteConfirmed
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
            guard sort != self.sort else { return nil }
            self.sort = sort
            return .exit(.sortChanged(sort))

        // Every figure is converted on read, so a new currency needs no reload — only the totals
        // recomputing. Rebuilding the screen instead replayed the arrival count-up from zero.
        case .currencyChanged(let code):
            currency = code
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
            pendingDelete = subscription
            return nil

        case .deleteConfirmed:
            guard let pending = pendingDelete else { return nil }
            pendingDelete = nil
            // Gone from the list here, not when the store answers. The write is asynchronous, so
            // waiting for it meant the row survived the confirmation and then vanished a moment
            // later, outside any animation the tap had started — no matter what the view wrapped
            // around this call, there was nothing to animate inside it. If the write fails, the
            // reload that follows puts the row back, which is the honest outcome.
            all.removeAll { $0.id == pending.id }
            return .delete(pending.id)

        case .deleteAllRequested:
            isConfirmingDeleteAll = true
            return nil

        case .deleteAllConfirmed:
            isConfirmingDeleteAll = false
            return .deleteEverything

        case .confirmationDismissed:
            isConfirmingDeleteAll = false
            pendingDelete = nil
            return nil

        case .storeChanged:
            return .load
        }
    }
}
