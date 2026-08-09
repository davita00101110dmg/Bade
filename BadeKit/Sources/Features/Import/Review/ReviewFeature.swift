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
        decisions = detected.map { ReviewDecision(startingFrom: $0.confidence) }
    }

    public var sections: [ReviewSection] {
        Confidence.reviewOrder.compactMap { confidence in
            let items = detected.indices
                .filter { detected[$0].confidence == confidence && decisions[$0] != .dismissed }
                .map {
                    ReviewItem(
                        id: $0, subscription: detected[$0], decision: decisions[$0],
                        converted: rates.convert(
                            detected[$0].amount, from: detected[$0].currency, to: currency))
                }
            return items.isEmpty ? nil : ReviewSection(confidence: confidence, items: items)
        }
    }

    public var selectedCount: Int { decisions.count { $0 == .included } }
    public var canConfirm: Bool { selectedCount > 0 && !isSaving }

    /// The findings summary, which "not one" shrinks but unticking a box does not.
    public var remainingCount: Int { decisions.count { $0 != .dismissed } }

    public var monthlyTotal: Decimal {
        kept.map { Subscription(confirming: $0) }.monthlyTotal(in: currency, rates: rates).total
    }

    var selected: [DetectedSubscription] { pick { $0 == .included } }
    private var kept: [DetectedSubscription] { pick { $0 != .dismissed } }

    private func pick(_ isWanted: (ReviewDecision) -> Bool) -> [DetectedSubscription] {
        detected.indices.filter { isWanted(decisions[$0]) }.map { detected[$0] }
    }
}

public enum ReviewIntent: Equatable {
    case toggled(Int)
    case acceptedUncertain(Int)
    case rejectedUncertain(Int)
    case confirmTapped
    case saved
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

        case .saved:
            isSaving = false
            return .exit(.saved)

        case .saveFailed:
            isSaving = false
            didFailToSave = true
            return nil

        case .closeTapped:
            return .exit(.cancelled)
        }
    }
}
