import Core
import Foundation

public struct ReviewState: Equatable {
    public let detected: [DetectedSubscription]
    public let rates: RateBook
    /// What totals are shown in. Supplied by the composition root until Settings owns it (§10).
    public let currency: String
    public private(set) var decisions: [ReviewDecision]
    public private(set) var isSaving = false
    public private(set) var didFailToSave = false

    public init(detected: [DetectedSubscription], rates: RateBook, currency: String) {
        self.detected = detected
        self.rates = rates
        self.currency = currency
        decisions = detected.map(ReviewDecision.init(startingFrom:))
    }

    /// The live tiers first, then anything that has already stopped, kept apart from them.
    public var sections: [ReviewSection] {
        let tiers = Confidence.reviewOrder.map(ReviewSection.Kind.tier) + [.ended]
        return tiers.compactMap { kind in
            let items = self.items { detected in
                switch kind {
                case .ended: detected.hasEnded
                case .tier(let confidence): !detected.hasEnded && detected.confidence == confidence
                }
            }
            return items.isEmpty ? nil : ReviewSection(kind: kind, items: items)
        }
    }

    private func items(where isIncluded: (DetectedSubscription) -> Bool) -> [ReviewItem] {
        detected.indices
            .filter { decisions[$0] != .dismissed && isIncluded(detected[$0]) }
            .map {
                ReviewItem(
                    id: $0, subscription: detected[$0], decision: decisions[$0],
                    converted: rates.convert(
                        detected[$0].amount, from: detected[$0].currency, to: currency,
                        on: detected[$0].nextChargeDate))
            }
    }

    public var selectedCount: Int { decisions.count { $0 == .included } }
    public var canConfirm: Bool { selectedCount > 0 && !isSaving }

    /// What ticking adds up to, so the header, the button and the total after saving all state the
    /// same figure. Something already ended is confirmed as cancelled, so it moves the count and
    /// not the money — a subscription that stopped is a record, not spend.
    public var monthlyTotal: Decimal {
        selected.map { Subscription(confirming: $0) }.monthlyTotal(in: currency, rates: rates).total
    }

    var selected: [DetectedSubscription] {
        detected.indices.filter { decisions[$0] == .included }.map { detected[$0] }
    }
}

public enum ReviewIntent: Equatable {
    case toggled(Int)
    case acceptedUncertain(Int)
    case rejectedUncertain(Int)
    case confirmTapped
    case saved(addedCount: Int)
    case saveFailed
    case closeTapped
}

public enum ReviewEffect: Equatable {
    case save([DetectedSubscription])
    case exit(ReviewOutcome)
}

extension ReviewState {
    public mutating func apply(_ intent: ReviewIntent) -> ReviewEffect? {
        switch intent {
        case .toggled(let id):
            decisions[id] = decisions[id] == .included ? .excluded : .included
            return nil

        case .acceptedUncertain(let id):
            decisions[id] = .included
            return nil

        case .rejectedUncertain(let id):
            decisions[id] = .dismissed
            return nil

        case .confirmTapped:
            guard canConfirm else { return nil }
            isSaving = true
            didFailToSave = false
            return .save(selected)

        case .saved(let addedCount):
            isSaving = false
            return .exit(.saved(addedCount: addedCount))

        case .saveFailed:
            isSaving = false
            didFailToSave = true
            return nil

        case .closeTapped:
            return .exit(.cancelled)
        }
    }
}
