import Core

/// What the user has said about one detection. Confident arrives `included`, probable `excluded`,
/// uncertain `undecided` — the brief forbids silently adding anything the engine is unsure of.
public enum ReviewDecision: Equatable, Sendable {
    case included
    case excluded
    /// Uncertain only: shown as a two-way choice rather than a checkbox.
    case undecided
    /// Uncertain only, answered "not one": gone from the list.
    case dismissed

    /// Anything already ended starts unticked, whatever the engine made of it. Nothing that stopped
    /// should be added to a list of what someone pays without them saying so — and it keeps that
    /// section to one kind of row, since `undecided` is what draws the two-way card.
    init(startingFrom detected: DetectedSubscription) {
        guard !detected.hasEnded else {
            self = .excluded
            return
        }
        switch detected.confidence {
        case .confident: self = .included
        case .probable: self = .excluded
        case .uncertain: self = .undecided
        }
    }
}
