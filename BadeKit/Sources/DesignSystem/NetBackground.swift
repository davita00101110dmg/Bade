import SwiftUI

/// The brand motif: ბადე means "net". A fine mesh, solid at the centre and dissolving outward,
/// masked exactly as the v1 design specifies.
public struct NetBackground: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let pitch: CGFloat = 17
    private let center = UnitPoint(x: 0.5, y: 0.46)

    /// 0 hides the net, 1 shows it at full strength.
    public var strength: Double

    public init(strength: Double = 1) {
        self.strength = strength
    }

    public var body: some View {
        GeometryReader { proxy in
            let extent = max(proxy.size.width, proxy.size.height)
            Canvas { context, size in
                context.stroke(mesh(in: size), with: .color(theme.net), lineWidth: 1)
            }
            .opacity(reduceTransparency ? 0 : 0.32 * strength)
            .mask(
                RadialGradient(
                    colors: [.black, .clear],
                    center: center,
                    startRadius: extent * 0.08,
                    endRadius: extent * 0.68)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mesh(in size: CGSize) -> Path {
        var path = Path()
        for column in stride(from: 0, through: size.width, by: pitch) {
            path.move(to: CGPoint(x: column, y: 0))
            path.addLine(to: CGPoint(x: column, y: size.height))
        }
        for row in stride(from: 0, through: size.height, by: pitch) {
            path.move(to: CGPoint(x: 0, y: row))
            path.addLine(to: CGPoint(x: size.width, y: row))
        }
        return path
    }
}
