import Localization
import SwiftUI

public struct BadeProgressBar: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `nil` while there is nothing to measure yet. Work that has not reported a fraction should
    /// say it is working, not claim to be nought percent through.
    private let progress: Double?
    private let pace: Animation

    @State private var isSweeping = false

    /// `pace` should match how often progress changes, so the fill glides between steps instead
    /// of snapping to each one.
    public init(progress: Double?, pace: Animation = .badeContent) {
        self.progress = progress.map { min(max($0, 0), 1) }
        self.pace = pace
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.surfaceSunken)
                if let progress {
                    Capsule()
                        .fill(theme.accent)
                        .frame(width: proxy.size.width * progress)
                        .badeAnimation(pace, value: progress)
                } else {
                    sweep(across: proxy.size.width)
                }
            }
            // The travelling fill is offset the whole width of the bar, so without this it rides
            // out past both ends instead of running along inside.
            .clipShape(Capsule())
        }
        .frame(height: BadeProgressBarMetrics.height)
        .accessibilityElement()
        .accessibilityLabel(Text(.common.progress))
        .accessibilityValue(accessibilityValue)
    }

    /// A short fill travelling the bar, over and over. Under Reduce Motion it does not travel: the
    /// bar simply sits filled and dimmed, which says "working" without anything moving.
    private func sweep(across width: CGFloat) -> some View {
        Capsule()
            .fill(theme.accent)
            .opacity(reduceMotion ? BadeProgressBarMetrics.restingOpacity : 1)
            .frame(width: width * (reduceMotion ? 1 : BadeProgressBarMetrics.sweepShare))
            .offset(x: sweepOffset(across: width))
            .animation(
                reduceMotion
                    ? nil
                    : .linear(duration: BadeProgressBarMetrics.sweepDuration)
                        .repeatForever(autoreverses: false),
                value: isSweeping)
            .onAppear { isSweeping = true }
    }

    private func sweepOffset(across width: CGFloat) -> CGFloat {
        guard !reduceMotion else { return 0 }
        return isSweeping ? width : -width * BadeProgressBarMetrics.sweepShare
    }

    private var accessibilityValue: Text {
        guard let progress else { return Text(.common.working) }
        return Text(progress.formatted(.percent.precision(.fractionLength(0))))
    }
}

/// The bar's own dimensions, which are its business and not the spacing scale's.
public enum BadeProgressBarMetrics {
    public static let height: CGFloat = 6
    /// How much of the bar the travelling fill takes up while there is nothing to measure.
    public static let sweepShare: CGFloat = 0.35
    public static let sweepDuration = 1.1
    public static let restingOpacity = 0.4
}
