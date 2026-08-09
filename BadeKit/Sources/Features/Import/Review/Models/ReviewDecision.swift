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

    init(startingFrom confidence: Confidence) {
        switch confidence {
        case .confident: self = .included
        case .probable: self = .excluded
        case .uncertain: self = .undecided
        }
    }
}
