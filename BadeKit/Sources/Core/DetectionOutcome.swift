import Foundation

/// Everything one pass over a statement concluded: what it is sure enough to report, and what it
/// could not explain but saw too often to ignore.
public struct DetectionOutcome: Equatable, Sendable {
    public let subscriptions: [DetectedSubscription]
    public let candidates: [RepeatCandidate]

    public init(subscriptions: [DetectedSubscription], candidates: [RepeatCandidate]) {
        self.subscriptions = subscriptions
        self.candidates = candidates
    }

    public static let empty = DetectionOutcome(subscriptions: [], candidates: [])
}
