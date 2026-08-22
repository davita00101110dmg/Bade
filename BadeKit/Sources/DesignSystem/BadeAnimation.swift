import SwiftUI

/// Motion vocabulary. Named by what the motion means, not by duration, so a screen asks for
/// `.badeSelection` rather than inventing a number.
extension Animation {
    /// Press feedback on buttons and controls.
    public static let badePress: Animation = .snappy(duration: 0.18)
    /// A selection moving: segmented controls, toggles, pickers.
    public static let badeSelection: Animation = .snappy(duration: 0.22)
    /// Content appearing or changing in place.
    public static let badeContent: Animation = .smooth(duration: 0.3)
    /// Moving between screens or major states.
    public static let badeTransition: Animation = .smooth(duration: 0.4)
    /// The net dissolving as the app fills with data.
    public static let badeNet: Animation = .easeInOut(duration: 0.8)
    /// The wordmark rising into place as the app opens. Slower than `badeContent` because it is
    /// the only thing on screen and has nothing to be quick for.
    public static let badeLaunch: Animation = .smooth(duration: 0.55)
    /// Something landing in the net and settling: it overshoots a little, which is what tells the
    /// eye the row arrived rather than appeared.
    public static let badeCatch: Animation = .spring(response: 0.34, dampingFraction: 0.58)
    /// Rows changing places. Damped harder than a catch — the point is watching a row travel to
    /// where it now belongs, and a bounce at the end of that journey only obscures it.
    public static let badeReorder: Animation = .spring(response: 0.42, dampingFraction: 0.86)
    /// The monthly total counting up — §14.7's arrival moment, and the one place the brief says
    /// to spend animation budget. Eases out so it settles rather than stopping dead.
    public static let badeTotalReveal: Animation = .easeOut(duration: BadeMotion.totalReveal)
}

/// Durations a view needs to know in seconds, because it has to wait for one to finish.
public enum BadeMotion {
    public static let totalReveal: TimeInterval = 0.9
}

extension View {
    /// Animates a change, honouring Reduce Motion in one place rather than per view. The change
    /// still happens — it simply arrives without movement.
    public func badeAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(BadeAnimationModifier(animation: animation, value: value))
    }
}

private struct BadeAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// Runs a change with Bade's motion, skipped entirely under Reduce Motion.
@MainActor
public func withBadeAnimation<Result>(
    _ animation: Animation, reduceMotion: Bool, _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(reduceMotion ? nil : animation, body)
}
