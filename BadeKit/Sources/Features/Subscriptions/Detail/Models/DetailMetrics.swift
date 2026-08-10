import CoreGraphics
import DesignSystem

/// The chart's own dimensions; the design drew a 96pt plot.
enum DetailMetrics {
    static let chartHeight: CGFloat = BadeSpacing.xxxl * 2
    /// A month with no charge still draws this much, so a gap is visible rather than absent.
    static let emptyBarHeight = BadeSpacing.xxs
    /// Months either side of the one being read out; faded, not hidden.
    static let dimmedBar = 0.25
}
