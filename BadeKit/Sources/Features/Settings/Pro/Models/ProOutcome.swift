/// Everything this screen hands back. Only the root can store an entitlement, and only it knows
/// what was locked while there was not one.
public enum ProOutcome: Equatable, Sendable {
    case unlocked
    case closed
    /// Tapped on the owned page, which lists what Pro added rather than what it would add. Only
    /// the root can change tabs, and Upcoming is the one feature with somewhere to go.
    case showUpcoming
}
