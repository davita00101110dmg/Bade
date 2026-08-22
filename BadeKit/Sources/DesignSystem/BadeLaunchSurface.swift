import Localization
import SwiftUI

/// The first frame the app draws, held while a local read decides where to go.
///
/// The wordmark rises into place and the full stop arrives a beat behind it, on nothing but the
/// app's own surface. The settled frame is what the system's generated launch image shows, so a
/// launch too fast to animate lands on the same picture rather than on a different one — which is
/// the whole reason there is no net here any more.
public struct BadeLaunchSurface: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasRisen = false
    @State private var hasLanded = false

    /// Called once the arrival has finished, so the root can wait for it rather than cutting it off
    /// — the read that decides where to go takes a fraction of the time this does.
    private let onSettled: () -> Void

    public init(onSettled: @escaping () -> Void = {}) {
        self.onSettled = onSettled
    }

    public var body: some View {
        HStack(spacing: .zero) {
            Text(.app.wordmark)
                .foregroundStyle(theme.ink)
            // Punctuation rather than part of the name, which is what lets it carry the accent and
            // arrive on its own. `scaleEffect` is a render transform, so `bade` never shifts.
            Text(verbatim: ".")
                .foregroundStyle(theme.accent)
                .scaleEffect(hasLanded ? 1 : BadeWordmarkMetrics.dotStartScale)
                .opacity(hasLanded ? 1 : 0)
        }
        .font(.badeTotal(size: BadeTypography.wordmarkSize))
        .tracking(BadeWordmarkMetrics.tracking)
        .opacity(hasRisen ? 1 : 0)
        .offset(y: hasRisen ? .zero : BadeWordmarkMetrics.rise)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(.app.name)
        .task {
            withBadeAnimation(.badeLaunch, reduceMotion: reduceMotion) { hasRisen = true }
            withBadeAnimation(
                .badeCatch.delay(BadeWordmarkMetrics.dotDelay), reduceMotion: reduceMotion
            ) { hasLanded = true }
            // Reduce Motion asked for no movement, so there is nothing to wait for and holding the
            // app back would only be a delay.
            if !reduceMotion {
                try? await Task.sleep(for: .seconds(BadeWordmarkMetrics.settle))
            }
            onSettled()
        }
    }
}
