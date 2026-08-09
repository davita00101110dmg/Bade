import CoreGraphics

/// The 4-point scale. Every gap and padding in the app comes from here.
public enum BadeSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48

    /// Standard left and right screen margin.
    public static let screenMargin: CGFloat = xl
}

/// Lets the scale be written as `VStack(spacing: .xs)` or `.padding(.top, .lg)`.
extension CGFloat {
    public static let xxs = BadeSpacing.xxs
    public static let xs = BadeSpacing.xs
    public static let sm = BadeSpacing.sm
    public static let md = BadeSpacing.md
    public static let lg = BadeSpacing.lg
    public static let xl = BadeSpacing.xl
    public static let xxl = BadeSpacing.xxl
    public static let xxxl = BadeSpacing.xxxl
    public static let screenMargin = BadeSpacing.screenMargin
}

public enum BadeRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
}

/// A component's own dimensions are its business, not the spacing scale's. Values are snapped
/// to the 4-point ladder: the design drew 18, 14 and 22.
public enum BadeButtonMetrics {
    public static let primaryVerticalPadding = BadeSpacing.md
    public static let secondaryVerticalPadding = BadeSpacing.md
    public static let cornerRadius = BadeRadius.xl
}

public enum BadeStepMetrics {
    public static let badgeSize = BadeSpacing.xl
    public static let cornerRadius = BadeRadius.sm
}

/// Rules rather than style. 44pt is the minimum touch target Apple's accessibility guidance
/// requires, and it is enforced on controls whose visual size is smaller.
public enum BadeLayout {
    public static let minimumTapTarget: CGFloat = 44
}
