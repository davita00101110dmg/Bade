import SwiftUI

public struct BadeProgressBar: View {
    @Environment(\.badeTheme) private var theme

    private let progress: Double
    private let pace: Animation
    private let height: CGFloat = 6

    /// `pace` should match how often progress changes, so the fill glides between steps instead
    /// of snapping to each one.
    public init(progress: Double, pace: Animation = .badeContent) {
        self.progress = min(max(progress, 0), 1)
        self.pace = pace
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.surfaceSunken)
                Capsule()
                    .fill(theme.accent)
                    .frame(width: proxy.size.width * progress)
                    .badeAnimation(pace, value: progress)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text(progress.formatted(.percent.precision(.fractionLength(0)))))
    }
}
