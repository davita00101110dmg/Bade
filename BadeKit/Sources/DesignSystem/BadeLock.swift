import Localization
import SwiftUI

/// How much room the lock has to sell in. A whole screen can carry the pitch; a card inside a
/// scrolling screen has to say it in one line and get out of the way.
public enum BadeLockScale: Sendable {
    case screen
    case card
}

extension EnvironmentValues {
    /// Whether what is being drawn sits under a lock, and so cannot be touched.
    ///
    /// Read by anything that would otherwise teach a gesture the content cannot accept. A tip is
    /// presented by the system in a window of its own, so it floats above the lock instead of being
    /// covered by it — offering to teach a tap on a calendar nobody can tap.
    @Entry public var badeIsLocked = false
}

extension View {
    /// Puts a feature behind Bade Pro: what is locked stays visible and inert, caught in the net,
    /// because showing what is being offered sells it better than hiding it does.
    ///
    /// Takes a plain flag today. When there is a real purchase, the flag is the only thing that
    /// has to change.
    public func badeLocked(
        _ isLocked: Bool, scale: BadeLockScale = .screen, onUnlock: @escaping () -> Void
    ) -> some View {
        modifier(BadeLock(isLocked: isLocked, scale: scale, onUnlock: onUnlock))
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
    /// Inside a card the same bloom would spill over whatever sits above it — the chart, usually.
    public static let cardBleed: CGFloat = 40
    /// How far a card's own contents are washed out behind the offer. The blur does the hiding;
    /// this only stops the button having to sit on top of legible text.
    public static let cardScrim = 0.55
    /// Quiet enough to read as texture: a full-width mesh at full strength is graph paper.
    public static let netStrength = 0.5
    /// Where the mesh reaches full strength and where it starts leaving again, as shares of its own
    /// height. Between them sits the copy; outside them is the bleed, which is all dissolve.
    public static let netHoldsFrom = 0.26
    public static let netHoldsTo = 0.72
}

private struct BadeLock: ViewModifier {
    @Environment(\.badeTheme) private var theme

    let isLocked: Bool
    let scale: BadeLockScale
    let onUnlock: () -> Void

    func body(content: Content) -> some View {
        content
            .environment(\.badeIsLocked, isLocked)
            .blur(radius: isLocked ? BadeLockMetrics.blur : 0)
            .allowsHitTesting(!isLocked)
            .accessibilityHidden(isLocked)
            .overlay { if isLocked { veil } }
            .badeAnimation(.badeContent, value: isLocked)
    }

    /// The whole veil is the tap target: a tap on something you cannot use is a request to unlock it.
    @ViewBuilder
    private var veil: some View {
        switch scale {
        case .screen: screenVeil
        case .card: cardVeil
        }
    }

    /// A screen dissolves down the fade and is gone by the time the copy's own ground begins.
    ///
    /// The offer sits in the middle of what it has caught, with the screen dissolving into it from
    /// above and back out of it below. Both gradients are flexible and equal, which is what centres
    /// the block — and they are why it never floats on legible content the way a bare overlay would.
    private var screenVeil: some View {
        VStack(spacing: .zero) {
            fade(from: .top, to: .bottom)
            message
                .background(net)
                .background(theme.surface)
            fade(from: .bottom, to: .top)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onUnlock)
    }

    /// A card gets the button and nothing else. It tried to carry the pitch as well, and the copy's
    /// own ground hugged its text rather than the card, so blurred words stuck out on either side of
    /// an opaque band — and the tagline was squeezed onto one line and truncated. There is no room
    /// for a sales page inside something the reader is scrolling past.
    private var cardVeil: some View {
        action
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.surface.opacity(BadeLockMetrics.cardScrim))
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

            action
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .screenMargin)
        .padding(.vertical, .xl)
    }

    /// Full width where the lock owns the screen, hugging its own text where it owns only a card.
    @ViewBuilder
    private var action: some View {
        if scale == .screen {
            Button(action: onUnlock) { Text(.locked.action) }.buttonStyle(.badePrimary)
        } else {
            Button(action: onUnlock) { Text(.locked.action) }.buttonStyle(.badeCompact)
        }
    }

    private func fade(from start: UnitPoint, to end: UnitPoint) -> LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: theme.surface.opacity(0), location: 0),
                Gradient.Stop(color: theme.surface, location: BadeLockMetrics.fadeCompletion),
            ],
            startPoint: start, endPoint: end)
    }

    /// Overflows the copy on every side, so the mesh reaches up over the screen it has caught.
    ///
    /// Masked at both ends. The mesh's own falloff is measured against the widest side of its
    /// canvas, so on a block far wider than it is tall it is still at strength when the canvas runs
    /// out and the grid stops on a line. Fading only the bottom moved that line to the top; the
    /// mask holds the mesh solid behind the copy and dissolves it through the bleed either side.
    private var net: some View {
        NetBackground(strength: BadeLockMetrics.netStrength)
            .padding(-BadeLockMetrics.netBleed)
            .mask(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: .white.opacity(0), location: 0),
                        Gradient.Stop(color: .white, location: BadeLockMetrics.netHoldsFrom),
                        Gradient.Stop(color: .white, location: BadeLockMetrics.netHoldsTo),
                        Gradient.Stop(color: .white.opacity(0), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom))
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
