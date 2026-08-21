import SwiftUI

/// Lari falling past the total, for finding the one thing in Bade that is not about being told what
/// your subscriptions cost.
///
/// Driven by a clock rather than by one animation, so every note can sway and turn on its own way
/// down instead of all sliding along the same line. Depth does most of the work: the far notes are
/// small, pale, blurred and slow, the near ones large, solid and quick, and nothing ever pops in or
/// out because each note fades at both ends of its fall.
///
/// Silent under Reduce Motion, and hidden from VoiceOver — there is nothing here to describe.
public struct BadeMoneyRain: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let symbol: String

    @State private var landings = 0

    public init(symbol: String) {
        self.symbol = symbol
    }

    public var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { context in
                Canvas { canvas, size in
                    draw(in: &canvas, size: size, at: context.date.timeIntervalSinceReferenceDate)
                } symbols: {
                    ForEach(0..<BadeMoneyRainMetrics.depths, id: \.self) { depth in
                        note(atDepth: depth).tag(depth)
                    }
                }
            }
            // Over the whole window, not just the content: bounded by the safe area the notes
            // appeared out of thin air just under the navigation bar instead of falling past it.
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .badeFeedback(.noteLanded, trigger: landings)
            .task { await patter() }
        }
    }

    /// A handful of taps, spaced out as they go, so the rain is felt starting and then let be.
    /// Scripted rather than tied to any one note: the notes are drawn in a `Canvas` and have no
    /// idea when they cross anything.
    private func patter() async {
        for gap in BadeMoneyRainMetrics.patter {
            try? await Task.sleep(for: gap)
            landings += 1
        }
    }

    /// One rendered glyph per depth, reused for every note at that depth. Drawing thirty separate
    /// `Text` views would lay out thirty times a frame; this lays out three, once.
    private func note(atDepth depth: Int) -> some View {
        let near = Double(depth) / Double(BadeMoneyRainMetrics.depths - 1)
        return Text(verbatim: symbol)
            .font(.badeTotal(size: BadeMoneyRainMetrics.size(near: near)))
            .foregroundStyle(theme.accent.opacity(BadeMoneyRainMetrics.opacity(near: near)))
            .blur(radius: BadeMoneyRainMetrics.blur(near: near))
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize, at time: TimeInterval) {
        for index in 0..<BadeMoneyRainMetrics.count {
            let note = Note(index: index, in: size, at: time)
            guard let symbol = canvas.resolveSymbol(id: note.depth) else { continue }

            canvas.drawLayer { layer in
                layer.opacity = note.fade
                layer.translateBy(x: note.x, y: note.y)
                layer.rotate(by: .degrees(note.turn))
                layer.draw(symbol, at: .zero)
            }
        }
    }

    /// Where one note is, right now. Everything comes from its index, so the fall is the same every
    /// time it is summoned — a thing that was designed rather than a thing that happened.
    private struct Note {
        let x: CGFloat
        let y: CGFloat
        let turn: Double
        let fade: Double
        let depth: Int

        init(index: Int, in size: CGSize, at time: TimeInterval) {
            // The golden ratio scatters the columns without them ever queueing up in a line.
            let scatter = (Double(index) * 0.618).truncatingRemainder(dividingBy: 1)
            let offset = (Double(index) * 0.381).truncatingRemainder(dividingBy: 1)
            depth = index % BadeMoneyRainMetrics.depths
            let near = Double(depth) / Double(BadeMoneyRainMetrics.depths - 1)

            let fall = BadeMoneyRainMetrics.fall(near: near)
            let progress = ((time / fall) + offset).truncatingRemainder(dividingBy: 1)
            y = CGFloat(progress) * (size.height + BadeMoneyRainMetrics.margin * 2)
                - BadeMoneyRainMetrics.margin

            let sway = sin(time * BadeMoneyRainMetrics.swaySpeed + Double(index))
            x = size.width * CGFloat(scatter) + CGFloat(sway) * BadeMoneyRainMetrics.sway
            turn = sway * BadeMoneyRainMetrics.turn

            // Fades in over the first tenth of the fall and out over the last, so nothing appears
            // or vanishes on screen.
            fade = min(progress / 0.1, (1 - progress) / 0.1, 1)
        }
    }
}

/// The rain's own numbers, which are its business and not the spacing scale's.
public enum BadeMoneyRainMetrics {
    public static let count = 30
    /// How many planes of depth the notes are spread across.
    public static let depths = 3

    public static func size(near: Double) -> CGFloat { 16 + 30 * near }
    public static func opacity(near: Double) -> Double { 0.25 + 0.55 * near }
    public static func blur(near: Double) -> CGFloat { CGFloat(2.5 * (1 - near)) }
    /// Seconds for one note to cross the screen. The near ones fall fastest.
    public static func fall(near: Double) -> Double { 3.4 - 1.6 * near }

    /// How far above and below the screen a note lives before it is on its way back round. Wide
    /// enough that even the largest note is fully clear of both edges.
    public static let margin: CGFloat = 140
    public static let sway: CGFloat = 22
    public static let swaySpeed = 0.9
    public static let turn: Double = 14
    /// Long enough for a full fall at the slowest depth, so nothing is cut off mid-air.
    public static let lifetime: Duration = .milliseconds(3600)
    /// Gaps between the taps that are felt as the rain starts, opening out so it fades rather
    /// than stops. Deliberately short of the full lifetime: it should be felt beginning, not
    /// drummed all the way through.
    public static let patter: [Duration] = [
        .milliseconds(120), .milliseconds(140), .milliseconds(190),
        .milliseconds(260), .milliseconds(360), .milliseconds(520),
    ]
}
