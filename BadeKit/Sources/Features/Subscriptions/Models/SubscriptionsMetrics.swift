import CoreGraphics
import DesignSystem

/// A cancelled row stays legible but plainly no longer counted.
enum SubscriptionsMetrics {
    static let cancelledRow = 0.45
}

/// The monogram's own dimensions; the design drew 36 with a 10pt corner.
enum MonogramMetrics {
    static let size = BadeSpacing.xxl
    static let cornerRadius = BadeRadius.md
}
