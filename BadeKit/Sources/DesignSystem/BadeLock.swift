import Localization
import SwiftUI

extension View {
    /// Puts a feature behind Bade Pro: the screen stays visible and inert, caught in the net,
    /// because showing what is being offered sells it better than hiding it does.
    ///
    /// Takes a plain flag today. When there is a real purchase, the flag is the only thing that
    /// has to change.
    public func badeLocked(_ isLocked: Bool, onUnlock: @escaping () -> Void) -> some View {
        modifier(BadeLock(isLocked: isLocked, onUnlock: onUnlock))
    }
}

/// The lock's own dimensions, which are its business and not the spacing scale's.
public enum BadeLockMetrics {
    /// Softens the screen without making it look broken; the fade, not the blur, does the hiding.
    public static let blur: CGFloat = 2
    /// Where down the fade the screen has gone entirely, leaving solid ground for the copy.
    public static let fadeCompletion = 0.88
    /// How far the mesh blooms past the copy, so it dissolves into the screen rather than ending.
    public static let netBleed: CGFloat = 128
    /// Quiet enough to read as texture: a full-width mesh at full strength is graph paper.
    public static let netStrength = 0.5
}

private struct BadeLock: ViewModifier {
    @Environment(\.badeTheme) private var theme

    let isLocked: Bool
    let onUnlock: () -> Void

    func body(content: Content) -> some View {
        content
            .blur(radius: isLocked ? BadeLockMetrics.blur : 0)
            .allowsHitTesting(!isLocked)
            .accessibilityHidden(isLocked)
            .overlay { if isLocked { veil } }
            .badeAnimation(.badeContent, value: isLocked)
    }

    /// The whole veil is the tap target: a tap on a screen you cannot use is a request to unlock it.
    /// The screen dissolves down the fade and is gone by the time the copy's own ground begins.
    private var veil: some View {
        VStack(spacing: .zero) {
            fade
            message
                .background(net)
                .background(theme.surface, ignoresSafeAreaEdges: .bottom)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onUnlock)
    }

    /// No card: the copy sits on the app's own surface, with the mesh blooming up out of it.
    private var message: some View {
        VStack(spacing: .lg) {
            VStack(spacing: .sm) {
                Text(.locked.title)
                    .font(.badeDisplay)
                    .foregroundStyle(theme.ink)
                Text(.pro.tagline)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            Button(action: onUnlock) { Text(.locked.action) }
                .buttonStyle(.badePrimary)
        }
        .padding(.horizontal, .screenMargin)
        .padding(.vertical, .xl)
    }

    private var fade: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: theme.surface.opacity(0), location: 0),
                Gradient.Stop(color: theme.surface, location: BadeLockMetrics.fadeCompletion),
            ],
            startPoint: .top, endPoint: .bottom)
    }

    /// Overflows the copy on every side, so the mesh reaches up over the screen it has caught.
    private var net: some View {
        NetBackground(strength: BadeLockMetrics.netStrength)
            .padding(-BadeLockMetrics.netBleed)
    }
}

#if DEBUG
    /// Stands in for a locked screen: something with a title, a grid and money in it to be caught.
    private struct LockPreview: View {
        @Environment(\.badeTheme) private var theme

        var body: some View {
            VStack(alignment: .leading, spacing: .lg) {
                Text(.upcoming.title)
                    .font(.badeDisplay)
                    .foregroundStyle(theme.ink)

                ForEach(0..<7, id: \.self) { _ in
                    HStack(spacing: .md) {
                        ForEach(0..<7, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: BadeRadius.sm, style: .continuous)
                                .fill(theme.surfaceRaised)
                                .frame(height: BadeLayout.minimumTapTarget)
                        }
                    }
                }
            }
            .padding(.screenMargin)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.surface, ignoresSafeAreaEdges: .all)
            .badeLocked(true) {}
        }
    }

    #Preview("Lock") {
        LockPreview().badeTheme()
    }

    #Preview("Lock · Dark") {
        LockPreview().badeTheme().preferredColorScheme(.dark)
    }

    #Preview("Lock · Georgian") {
        LockPreview().badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Lock · Large text") {
        LockPreview().badeTheme().environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
