import Core
import Foundation
import Localization

/// One detection as the list renders it. `id` is its position in the import, which never moves.
public struct ReviewItem: Equatable, Identifiable, Sendable {
    public let id: Int
    public let subscription: DetectedSubscription
    public let decision: ReviewDecision
    /// The charge in the display currency, or `nil` when the statement carried no rate for it.
    public let converted: Decimal?
}

/// A confidence tier with its rows. Empty tiers are dropped before the view sees them.
public struct ReviewSection: Equatable, Identifiable, Sendable {
    public let confidence: Confidence
    public let items: [ReviewItem]

    public var id: String { confidence.rawValue }
}

extension Confidence {
    /// Most certain first, so the user meets the rows that need no thought before the ones that do.
    static let reviewOrder: [Confidence] = [.confident, .probable, .uncertain]
}

extension ReviewSection {
    var title: LocalizedStringResource {
        switch confidence {
        case .confident: .review.tierConfident
        case .probable: .review.tierProbable
        case .uncertain: .review.tierUncertain
        }
    }

    /// What earned the tier, stated plainly. "Not sure" speaks for itself.
    var hint: LocalizedStringResource? {
        switch confidence {
        case .confident: .review.confidentHint
        case .probable: .review.probableHint
        case .uncertain: nil
        }
    }
}
