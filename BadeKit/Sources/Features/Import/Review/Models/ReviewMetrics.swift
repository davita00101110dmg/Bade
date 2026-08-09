import CoreGraphics
import DesignSystem

/// The checkbox's own dimensions, snapped to the scale; the design drew 22 with a 1.5 stroke.
enum ReviewCheckboxMetrics {
    static let size = BadeSpacing.xl
    static let cornerRadius = BadeRadius.sm
    static let border: CGFloat = 1.5
}

/// The two-way answer under an uncertain detection. The design drew 38; a control this important
/// gets the full tap target instead.
enum ReviewChoiceMetrics {
    static let height = BadeLayout.minimumTapTarget
    static let cornerRadius = BadeRadius.md
}
