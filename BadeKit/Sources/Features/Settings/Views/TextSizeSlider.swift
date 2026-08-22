import DesignSystem
import Localization
import SwiftUI

/// Dragged rather than picked, the way iOS's own text size control works: the two A's show which
/// way is bigger, and the label names the stop you have landed on.
///
/// The handle starts on whatever size the app is already showing — the phone's, until someone
/// disagrees with it — so left is plainly smaller and right is plainly bigger, rather than the
/// scale starting at nothing.
struct TextSizeSlider: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.dynamicTypeSize) private var inherited

    @Binding var size: BadeTextSize

    private static let stops = BadeTextSize.scale

    var body: some View {
        VStack(alignment: .leading, spacing: .xs) {
            HStack {
                Text(.settings.textSize)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
                Spacer()
                Text(size.name)
                    .font(.badeCaption)
                    .foregroundStyle(theme.ink)
            }

            HStack(spacing: .sm) {
                marker(.badeCaption)
                Slider(value: position, in: 0...Double(Self.stops.count - 1), step: 1)
                    .tint(theme.accent)
                marker(.badeTitle)
            }
        }
        .padding(.vertical, .xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(.settings.textSize))
        .accessibilityValue(Text(size.name))
    }

    /// The scale's own letters, which must not resize with the setting they are describing.
    private func marker(_ font: Font) -> some View {
        Text(verbatim: "A")
            .font(font)
            .foregroundStyle(theme.inkFaint)
            .dynamicTypeSize(.large)
    }

    /// Note that `system` is not a stop, so dragging this leaves it and nothing here comes back:
    /// the app stops following the phone's text size for good. iOS's own per-app setting still
    /// overrides, but Bade offers no way home.
    private var position: Binding<Double> {
        Binding(
            get: { Double(Self.stops.firstIndex(of: size) ?? inheritedStop) },
            set: { size = Self.stops[Int($0.rounded())] })
    }

    /// Following the phone is not a stop, so the handle sits on whichever stop matches what the
    /// phone is currently asking for, and falls back to the default when it is beyond the scale.
    private var inheritedStop: Int {
        Self.stops.firstIndex { $0.dynamicTypeSize == inherited }
            ?? Self.stops.firstIndex(of: .standard) ?? 0
    }
}
