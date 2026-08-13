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

/// A group of rows with its heading. Empty groups are dropped before the view sees them.
public struct ReviewSection: Equatable, Identifiable, Sendable {
    /// What the rows have in common. Whether a subscription already stopped outranks how sure the
    /// engine is that it existed: mixed into the tiers, an ended charge reads as money still going
    /// out, which is the one thing it is not.
    public enum Kind: Equatable, Sendable {
        case tier(Confidence)
        case ended
    }

    public let kind: Kind
    public let items: [ReviewItem]

    public var id: String {
        switch kind {
        case .tier(let confidence): confidence.rawValue
        case .ended: "ended"
        }
    }
}

extension Confidence {
    /// Most certain first, so the user meets the rows that need no thought before the ones that do.
    static let reviewOrder: [Confidence] = [.confident, .probable, .uncertain]
}

extension ReviewSection {
    var title: LocalizedStringResource {
        switch kind {
        case .tier(.confident): .review.tierConfident
        case .tier(.probable): .review.tierProbable
        case .tier(.uncertain): .review.tierUncertain
        case .ended: .review.tierEnded
        }
    }

    /// What earned the group, stated plainly. "Not sure" speaks for itself.
    var hint: LocalizedStringResource? {
        switch kind {
        case .tier(.confident): .review.confidentHint
        case .tier(.probable): .review.probableHint
        case .tier(.uncertain): nil
        case .ended: .review.endedHint
        }
    }
}
