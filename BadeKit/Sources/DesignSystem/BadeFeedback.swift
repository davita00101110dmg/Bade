import SwiftUI

/// Haptics named by what happened, so screens do not choose intensities themselves.
public enum BadeFeedback: Sendable {
    /// A row landing in a list as it fills — deliberately light, since many fire in sequence.
    case itemAppeared
    /// A note landing during the rain. Lighter still: several fall in a second and a half, and the
    /// point is a patter rather than a knock.
    case noteLanded
    case selection
    case success
    case failure

    var sensory: SensoryFeedback {
        switch self {
        case .itemAppeared: .impact(flexibility: .solid, intensity: 0.7)
        case .noteLanded: .impact(flexibility: .soft, intensity: 0.45)
        case .selection: .selection
        case .success: .success
        case .failure: .error
        }
    }
}

extension View {
    /// Fires when `trigger` changes. Haptics are never the only signal for an outcome — the
    /// visual change always carries the meaning on its own.
    public func badeFeedback<T: Equatable>(_ feedback: BadeFeedback, trigger: T) -> some View {
        sensoryFeedback(feedback.sensory, trigger: trigger)
    }
}
