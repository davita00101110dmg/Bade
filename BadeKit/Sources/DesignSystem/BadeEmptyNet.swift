import SwiftUI

/// Nothing here, said with the app's own motif rather than only in words: an empty net, with the
/// message resting in it.
///
/// The mesh is drawn quieter and narrower than anywhere else it appears. An empty state is a small
/// moment and should read as calm — a net at full strength over a sentence about having nothing
/// looks like an error rather than like a month with no charges in it.
public struct BadeEmptyNet<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .screenMargin)
            .padding(.vertical, BadeEmptyNetMetrics.breathing)
            .background(
                NetBackground(
                    strength: BadeEmptyNetMetrics.strength,
                    peakOpacity: BadeEmptyNetMetrics.opacity,
                    reachFactor: BadeEmptyNetMetrics.reach
                )
                .clipped(antialiased: true)
            )
    }
}

/// The empty net's own numbers, which are its business and not the spacing scale's.
public enum BadeEmptyNetMetrics {
    public static let strength = 1.0
    /// Fainter than the lock's mesh: this one is not catching anything.
    public static let opacity = 0.12
    /// Short, so the mesh is spent well inside its own bounds and never ends on a line.
    public static let reach: CGFloat = 0.3
    public static let breathing = BadeSpacing.xxxl
}
