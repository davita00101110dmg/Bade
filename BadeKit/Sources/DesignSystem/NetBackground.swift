import SwiftUI

/// The brand motif: ბადე means "net". Each segment fades by its own distance from the centre, so
/// the mesh dissolves into nothing rather than ending at an edge.
public struct NetBackground: View, Animatable {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let pitch = NetMetrics.pitch
    private let center = UnitPoint(x: 0.5, y: 0.46)
    private let fadeBias: Double = 1

    private let peakOpacity: Double
    private let reachFactor: CGFloat

    /// 0 hides the net, 1 shows it at full strength.
    public var strength: Double

    /// Behind a title block the mesh is texture and stays quiet; on the launch screen it is the
    /// picture, so both how dark it gets and how far it spreads are the caller's to say.
    public init(
        strength: Double = 1,
        peakOpacity: Double = NetMetrics.peakOpacity,
        reachFactor: CGFloat = NetMetrics.reachFactor
    ) {
        self.strength = strength
        self.peakOpacity = peakOpacity
        self.reachFactor = reachFactor
    }

    /// So the mesh can be woven in rather than switched on: a `Canvas` redraws per frame, but only
    /// if something tells SwiftUI the value between two strengths is worth interpolating.
    nonisolated public var animatableData: Double {
        get { strength }
        set { strength = newValue }
    }

    public var body: some View {
        Canvas(opaque: false) { context, size in
            guard !reduceTransparency, strength > 0 else { return }
            draw(in: &context, size: size)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let origin = CGPoint(x: size.width * center.x, y: size.height * center.y)
        let reach = max(size.width, size.height) * reachFactor
        let step = pitch / 2

        for column in stride(from: 0, through: size.width, by: pitch) {
            for y in stride(from: 0, through: size.height, by: step) {
                segment(
                    &context, from: CGPoint(x: column, y: y),
                    to: CGPoint(x: column, y: min(y + step, size.height)),
                    origin: origin, reach: reach)
            }
        }
        for row in stride(from: 0, through: size.height, by: pitch) {
            for x in stride(from: 0, through: size.width, by: step) {
                segment(
                    &context, from: CGPoint(x: x, y: row),
                    to: CGPoint(x: min(x + step, size.width), y: row),
                    origin: origin, reach: reach)
            }
        }
    }

    private func segment(
        _ context: inout GraphicsContext, from start: CGPoint, to end: CGPoint,
        origin: CGPoint, reach: CGFloat
    ) {
        let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let distance = hypot(midpoint.x - origin.x, midpoint.y - origin.y)
        let alpha = falloff(distance / reach) * strength
        guard alpha > 0.004 else { return }

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(theme.net.opacity(alpha)), lineWidth: 1)
    }

    /// Smoothstep, biased so the fade begins near the centre rather than holding a solid core.
    private func falloff(_ t: CGFloat) -> Double {
        let x = Double(min(max(1 - t, 0), 1))
        let smooth = x * x * (3 - 2 * x)
        return pow(smooth, fadeBias) * peakOpacity
    }
}

#if DEBUG
    private struct NetPreview: View {
        @Environment(\.badeTheme) private var theme

        var body: some View {
            ZStack {
                theme.surface
                NetBackground()
            }
            .ignoresSafeArea()
        }
    }

    #Preview("Net") {
        NetPreview().badeTheme()
    }

    #Preview("Net · Dark") {
        NetPreview().badeTheme().preferredColorScheme(.dark)
    }
#endif

/// The mesh's own dimensions. Its business, not the spacing scale's.
public enum NetMetrics {
    public static let pitch: CGFloat = 17
    /// Quiet enough behind a title block that it reads as texture rather than as graph paper.
    public static let peakOpacity = 0.17
    public static let reachFactor: CGFloat = 0.42
}

/// The net as a bounded panel, used behind a screen's title block rather than the whole page.
public struct NetPanel<Content: View>: View {

    /// How far the mesh bleeds past its content before it has faded out.
    private let bleed: CGFloat
    private let content: () -> Content

    public init(bleed: CGFloat = BadeSpacing.xxxl, @ViewBuilder content: @escaping () -> Content) {
        self.bleed = bleed
        self.content = content
    }

    public var body: some View {
        content().background(NetBackground().padding(-bleed))
    }
}
