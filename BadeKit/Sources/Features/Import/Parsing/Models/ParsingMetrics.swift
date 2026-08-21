import CoreGraphics

/// How a found subscription looks while it is still settling — its own business, not the spacing
/// scale's. `settling` runs 1 for the row that has just landed down to 0 once it has come to rest.
enum ParsingMetrics {
    /// How faint a row is at the moment it lands, before it firms up.
    static let settleFade = 0.65
    /// How much smaller it lands than it ends up. Small on purpose: the spring does the work, and
    /// anything larger reads as a bounce rather than as something being caught.
    static let settleScale = 0.05
}
