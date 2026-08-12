import CoreGraphics
import DesignSystem

/// The grid's own dimensions, which are its business and not the spacing scale's.
enum UpcomingMetrics {
    static let dotSize: CGFloat = 5
    static let cellHeight: CGFloat = 44
    static let tileRadius = BadeRadius.md
    static let selectionWidth: CGFloat = 2
    static let visibleDots = 3
    static let emptyDay = 0.35
    /// How far a sideways drag has to travel before it counts as turning the page.
    static let pageThreshold: CGFloat = 60
}
