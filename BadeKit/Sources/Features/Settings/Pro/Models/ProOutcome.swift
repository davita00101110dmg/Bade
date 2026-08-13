/// Everything this screen hands back. Only the root can store an entitlement, and only it knows
/// what was locked while there was not one.
public enum ProOutcome: Equatable, Sendable {
    case unlocked
    case closed
}
