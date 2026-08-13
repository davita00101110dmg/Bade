import Core
import DesignSystem
import Localization
import SwiftUI

/// Twelve months of charges. The shape is the point — a steady rhythm, a gap, or a step up — so
/// the bars carry no labels of their own; drag across them to read a month out.
struct ChargeHistoryChart: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let bars: [ChargeBar]
    let currency: String

    @State private var scrubbed: ChargeBar?
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            readout
            plot
            axisLabels
        }
        .badeFeedback(.selection, trigger: scrubbed?.month)
    }

    private var plot: some View {
        HStack(alignment: .bottom, spacing: .xxs) {
            ForEach(bars) { bar in
                RoundedRectangle(cornerRadius: BadeRadius.sm, style: .continuous)
                    .fill(colour(for: bar))
                    .frame(height: height(for: bar))
                    .frame(maxWidth: .infinity)
                    .opacity(dimmed(bar) ? DetailMetrics.dimmedBar : 1)
                    .accessibilityLabel(Text(verbatim: describe(bar)))
            }
        }
        .frame(height: DetailMetrics.chartHeight, alignment: .bottom)
        .contentShape(.rect)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .gesture(scrub)
        .badeAnimation(.badeSelection, value: scrubbed)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(.detail.history))
    }

    /// `minimumDistance: 0` so a touch reads out immediately rather than waiting for movement.
    private var scrub: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in scrubbed = bar(atX: value.location.x) }
            .onEnded { _ in scrubbed = nil }
    }

    /// Above the plot, because a hand reading the bars covers everything below them. A space holds
    /// the row's height open, so touching a month moves nothing.
    private var readout: some View {
        Text(verbatim: scrubbed.map(describe) ?? " ")
            .font(.badeCaptionStrong)
            .foregroundStyle(theme.ink)
            .frame(maxWidth: .infinity)
    }

    private var axisLabels: some View {
        HStack {
            Text(verbatim: monthLabel(bars.first?.month))
            Spacer()
            Text(verbatim: monthLabel(bars.last?.month))
        }
        .font(.badeCaption)
        .foregroundStyle(theme.inkFaint)
    }

    private func bar(atX x: CGFloat) -> ChargeBar? {
        guard width > 0, !bars.isEmpty else { return nil }
        let slot = width / CGFloat(bars.count)
        let index = min(bars.count - 1, max(0, Int(x / slot)))
        return bars[index]
    }

    private func dimmed(_ bar: ChargeBar) -> Bool {
        scrubbed != nil && scrubbed?.month != bar.month
    }

    /// An empty month still draws a sliver, so a gap reads as "nothing here" rather than as the
    /// chart having ended.
    private func height(for bar: ChargeBar) -> CGFloat {
        let usable = DetailMetrics.chartHeight - DetailMetrics.emptyBarHeight
        return DetailMetrics.emptyBarHeight + usable * bar.fraction
    }

    private func colour(for bar: ChargeBar) -> Color {
        if bar.isEmpty { return theme.surfaceSunken }
        return bar.isPriceRise ? theme.destructive : theme.net
    }

    private func describe(_ bar: ChargeBar) -> String {
        let month = monthLabel(bar.month)
        guard !bar.isEmpty else { return month }
        return "\(month) · \(bar.amount.formatted(.badeMoney(currency).locale(locale)))"
    }

    private func monthLabel(_ month: Date?) -> String {
        month?.formatted(.dateTime.month(.abbreviated).year().locale(locale)) ?? ""
    }
}
