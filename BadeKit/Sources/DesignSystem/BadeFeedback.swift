import SwiftUI

/// Haptics named by what happened, so screens do not choose intensities themselves.
public enum BadeFeedback: Sendable {
    /// A row landing in a list as it fills — deliberately light, since many fire in sequence.
    case itemAppeared
    case selection
    case success
    case failure

    var sensory: SensoryFeedback {
        switch self {
        case .itemAppeared: .impact(flexibility: .solid, intensity: 0.7)
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
