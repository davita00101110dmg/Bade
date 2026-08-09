/// Every way this screen can end, so the parent handles them in one exhaustive place.
public enum ReviewOutcome: Equatable, Sendable {
    case cancelled
    case saved
}
