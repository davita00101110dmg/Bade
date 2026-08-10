/// Every way this screen hands control back, so the parent handles them in one exhaustive place.
public enum DetailOutcome: Equatable, Sendable {
    /// The subscription changed; the list behind this screen is now stale.
    case changed
    case deleted
}
