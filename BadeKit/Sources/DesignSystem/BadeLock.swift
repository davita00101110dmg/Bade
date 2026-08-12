import Localization
import SwiftUI

extension View {
    /// Puts a feature behind Bade Pro: the screen stays visible and inert behind a scrim, because
    /// showing what is being offered sells it better than hiding it does.
    ///
    /// Takes a plain flag today. When there is a real purchase, the flag is the only thing that
    /// has to change.
    public func badeLocked(_ isLocked: Bool, onUnlock: @escaping () -> Void) -> some View {
        modifier(BadeLock(isLocked: isLocked, onUnlock: onUnlock))
    }
}

/// The lock's own dimensions, which are its business and not the spacing scale's.
public enum BadeLockMetrics {
    public static let blur: CGFloat = 6
    public static let scrim = 0.55
    public static let panelWidth: CGFloat = 320
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
            .overlay {
                if isLocked {
                    panel
                }
            }
            .badeAnimation(.badeContent, value: isLocked)
    }

    private var panel: some View {
        ZStack {
            theme.surface.opacity(BadeLockMetrics.scrim).ignoresSafeArea()

            BadeCard {
                VStack(spacing: .md) {
                    Image(systemName: "lock")
                        .font(.badeTitle)
                        .foregroundStyle(theme.accent)

                    VStack(spacing: .xs) {
                        Text(.locked.title)
                            .font(.badeTitle)
                            .foregroundStyle(theme.ink)
                        Text(.pro.tagline)
                            .font(.badeBody)
                            .foregroundStyle(theme.inkMuted)
                    }
                    .multilineTextAlignment(.center)

                    Button(action: onUnlock) { Text(.locked.action) }
                        .buttonStyle(.badePrimary)
                }
                .padding(.vertical, .sm)
            }
            .frame(maxWidth: BadeLockMetrics.panelWidth)
            .padding(.horizontal, .screenMargin)
        }
    }
}
