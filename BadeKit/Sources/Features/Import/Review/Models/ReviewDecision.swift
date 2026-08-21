import Core

/// What the user has said about one detection: ticked, or not. Every row asks the same way, so
/// there is nothing else to be.
public enum ReviewDecision: Equatable, Sendable {
    case included
    case excluded

    /// Only what the engine is sure of arrives ticked. The brief forbids silently adding anything
    /// weaker than that, and anything already ended is a record rather than a cost, whatever
    /// confidence it reached.
    init(startingFrom detected: DetectedSubscription) {
        self = detected.confidence == .confident && !detected.hasEnded ? .included : .excluded
    }
}
