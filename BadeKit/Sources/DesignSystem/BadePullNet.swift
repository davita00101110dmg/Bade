import SwiftUI

/// The web, hidden above the top of the list. Dragging the list down uncovers it: nothing for the
/// first stretch of the pull, then it fades up as more of it comes clear, and it is covered again
/// the moment you let go.
///
/// It holds still while the list slides off it, rather than travelling with the gesture — what
/// moves is the content, and this was always underneath. There is nothing to refresh either: every
/// figure in Bade is already local and already current, so it answers the gesture and nothing more.
public struct BadePullNet: View {
    /// How far the list has been dragged past its own top, in points.
    private let pull: CGFloat

    public init(pull: CGFloat) {
        self.pull = pull
    }

    /// Nothing at all until the pull is deliberate, then up to full across the rest of the reveal.
    private var uncovered: Double {
        let past = pull - BadePullNetMetrics.showsAfter
        guard past > 0 else { return 0 }
        return Double(min(1, past / BadePullNetMetrics.fullAt))
    }

    public var body: some View {
        Text(verbatim: BadePullNetMetrics.glyph)
            .font(.system(size: BadePullNetMetrics.size))
            .opacity(uncovered)
            .frame(maxWidth: .infinity)
            // Measured from the bottom of the uncovered strip, which is exactly where the list
            // begins. Pinned to the top instead, the two met as soon as the pull was deep enough
            // to show the whole web, and it landed on the label beneath it. This way the gap is
            // carried with it and they can never touch, however far the list is dragged.
            .padding(.bottom, BadePullNetMetrics.breathing)
            .frame(height: pull, alignment: .bottom)
            // Masked rather than clipped. A clip cut the web off on a hard line wherever the strip
            // happened to end, which under the navigation bar read as a slice through it; this way
            // it dissolves upward and goes under the bar instead of being cut by it.
            .mask(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: .white.opacity(0), location: 0),
                        Gradient.Stop(color: .white, location: BadePullNetMetrics.emergesBy),
                        Gradient.Stop(color: .white, location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The pulled web's own numbers, which are its business and not the spacing scale's.
public enum BadePullNetMetrics {
    public static let glyph = "🕸️"
    public static let size: CGFloat = 72
    /// Clear air kept between the web and the list it sits above, at any depth of pull.
    public static let breathing = BadeSpacing.xl
    /// How far the list has to be pulled before any of this begins to show.
    public static let showsAfter: CGFloat = 36
    /// And how much further before it is fully there.
    public static let fullAt: CGFloat = 80
    /// How far down the uncovered strip the web has fully emerged, as a share of that strip. Above
    /// it the web fades away into the navigation bar rather than ending on an edge.
    public static let emergesBy = 0.45
}
