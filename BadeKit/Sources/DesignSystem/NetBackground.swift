import SwiftUI

/// The brand motif: ბადე means "net". Each segment fades by its own distance from the centre, so
/// the mesh dissolves into nothing rather than ending at an edge.
public struct NetBackground: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let pitch: CGFloat = 17
    private let center = UnitPoint(x: 0.5, y: 0.46)

    // The three numbers worth tuning. Opacity at the centre, how far the mesh reaches before it
    // is gone, and how early the fade starts biting.
    private let peakOpacity: Double = 0.17
    private let reachFactor: CGFloat = 0.42
    private let fadeBias: Double = 1

    /// 0 hides the net, 1 shows it at full strength.
    public var strength: Double

    public init(strength: Double = 1) {
        self.strength = strength
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
