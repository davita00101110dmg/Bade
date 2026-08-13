import Core
import Foundation

/// How the whole import ended, from the composition root's point of view. Parsing's `finished`
/// never escapes the flow — it is what pushes Review.
public enum ImportOutcome: Equatable, Sendable {
    case cancelled
    case chooseAnother
    /// `addedCount` is how many subscriptions were not already stored. Zero means the statement had
    /// been imported before, which is worth saying out loud.
    case saved(addedCount: Int)
}

/// What Parsing hands to Review. Identity is the push itself, so re-parsing pushes a fresh screen
/// rather than diffing two statements against each other.
struct DetectedStatement: Identifiable, Hashable {
    let id = UUID()
    let detected: [DetectedSubscription]
    let rates: RateBook

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
