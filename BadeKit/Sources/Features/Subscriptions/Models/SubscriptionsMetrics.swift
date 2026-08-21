import CoreGraphics
import DesignSystem
import Foundation

/// A cancelled row stays legible but plainly no longer counted.
enum SubscriptionsMetrics {
    /// How far the list has to be scrolled before the toolbar takes the total over. Past the whole
    /// hero, so the handover happens once the figure has genuinely gone rather than as it clips.
    static let heroLeavesAt: CGFloat = 190
    /// Taps on the total, and how long a gap may fall between them, before it rains.
    static let tapsForRain = 5
    static let rainTapWindow: TimeInterval = 0.6
}

/// The monogram's own dimensions; the design drew 36 with a 10pt corner.
enum MonogramMetrics {
    static let size = BadeSpacing.xxl
    static let cornerRadius = BadeRadius.md
}
