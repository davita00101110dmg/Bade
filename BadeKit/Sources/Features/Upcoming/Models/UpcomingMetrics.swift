import CoreGraphics
import DesignSystem

/// The grid's own dimensions, which are its business and not the spacing scale's.
enum UpcomingMetrics {
    /// A day's dots are sized by what it cost against the month's heaviest day, between these.
    static let lightestDot: CGFloat = 4
    static let heaviestDot: CGFloat = 9
    /// A cancelled charge's dot is an outline rather than a disc.
    static let hollowDot: CGFloat = 1
    static let cellHeight: CGFloat = 44
    static let tileRadius = BadeRadius.md
    static let selectionWidth: CGFloat = 2
    static let visibleDots = 3
    static let emptyDay = 0.35
    /// How far a sideways drag has to travel before it counts as turning the page.
    static let pageThreshold: CGFloat = 60
}
