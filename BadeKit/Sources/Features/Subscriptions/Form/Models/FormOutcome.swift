import Core

/// Every way the form hands control back, so the screen that presented it handles them in one
/// exhaustive place.
public enum FormOutcome: Equatable, Sendable {
    /// Carries the saved subscription so the presenting screen can show it without a re-read.
    case saved(Subscription)
    case cancelled
}
