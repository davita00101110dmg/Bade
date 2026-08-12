import CoreGraphics
import DesignSystem

/// The chart's own dimensions. The design drew a 96pt plot; it is two and a half times that
/// here, because a bar you are touching is under your own hand at 96.
enum DetailMetrics {
    static let chartHeight: CGFloat = BadeSpacing.xxxl * 5
    /// A month with no charge still draws this much, so a gap is visible rather than absent.
    static let emptyBarHeight = BadeSpacing.xxs
    /// Months either side of the one being read out; faded, not hidden.
    static let dimmedBar = 0.25
}
