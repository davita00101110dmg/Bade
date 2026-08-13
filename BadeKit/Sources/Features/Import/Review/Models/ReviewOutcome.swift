/// Every way this screen can end, so the parent handles them in one exhaustive place.
public enum ReviewOutcome: Equatable, Sendable {
    case cancelled
    /// `addedCount` is how many were not already stored; zero means this
    /// statement had been imported before.
    case saved(addedCount: Int)
}
