import Core

/// Every way this screen can end, so the parent handles them in one exhaustive place.
public enum ParsingOutcome: Equatable, Sendable {
    case cancelled
    case chooseAnother
    case finished([DetectedSubscription], RateBook)
}
