import SwiftUI

/// Every colour the app uses, resolved for one appearance. Swap the whole look by injecting a
/// different theme; no view reaches for a palette value directly.
public struct BadeTheme: Sendable, Equatable {
    public var surface: Color
    public var surfaceRaised: Color
    public var surfaceSunken: Color
    public var ink: Color
    public var inkMuted: Color
    public var inkFaint: Color
    public var accent: Color
    public var accentPressed: Color
    public var border: Color
    public var net: Color
    public var positive: Color
    public var warning: Color
    public var destructive: Color

    public init(scheme: ColorScheme) {
        surface = BadePalette.surface.color(for: scheme)
        surfaceRaised = BadePalette.surfaceRaised.color(for: scheme)
        surfaceSunken = BadePalette.surfaceSunken.color(for: scheme)
        ink = BadePalette.ink.color(for: scheme)
        inkMuted = BadePalette.inkMuted.color(for: scheme)
        inkFaint = BadePalette.inkFaint.color(for: scheme)
        accent = BadePalette.accent.color(for: scheme)
        accentPressed = BadePalette.accentPressed.color(for: scheme)
        border = BadePalette.border.color(for: scheme)
        net = BadePalette.net.color(for: scheme)
        positive = BadePalette.positive.color(for: scheme)
        warning = BadePalette.warning.color(for: scheme)
        destructive = BadePalette.destructive.color(for: scheme)
    }

    public static let light = BadeTheme(scheme: .light)
    public static let dark = BadeTheme(scheme: .dark)

    /// The palette an appearance asks for. Anywhere the theme cannot be read from the environment
    /// — a widget's container background is extracted and drawn by the system, outside the view
    /// tree — this is how to arrive at the same answer rather than guessing at a default.
    public static func matching(_ scheme: ColorScheme) -> BadeTheme {
        scheme == .dark ? .dark : .light
    }
}

extension EnvironmentValues {
    @Entry public var badeTheme = BadeTheme.light
}

extension View {
    /// Applies the theme matching the current appearance. Set once, at the root.
    public func badeTheme() -> some View { modifier(BadeThemeModifier()) }
}

private struct BadeThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.environment(\.badeTheme, .matching(scheme))
    }
}
