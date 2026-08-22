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

    public init(scheme: ColorScheme, contrast: ColorSchemeContrast = .standard) {
        surface = BadePalette.surface.color(for: scheme, contrast: contrast)
        surfaceRaised = BadePalette.surfaceRaised.color(for: scheme, contrast: contrast)
        surfaceSunken = BadePalette.surfaceSunken.color(for: scheme, contrast: contrast)
        ink = BadePalette.ink.color(for: scheme, contrast: contrast)
        inkMuted = BadePalette.inkMuted.color(for: scheme, contrast: contrast)
        inkFaint = BadePalette.inkFaint.color(for: scheme, contrast: contrast)
        accent = BadePalette.accent.color(for: scheme, contrast: contrast)
        accentPressed = BadePalette.accentPressed.color(for: scheme, contrast: contrast)
        border = BadePalette.border.color(for: scheme, contrast: contrast)
        net = BadePalette.net.color(for: scheme, contrast: contrast)
        positive = BadePalette.positive.color(for: scheme, contrast: contrast)
        warning = BadePalette.warning.color(for: scheme, contrast: contrast)
        destructive = BadePalette.destructive.color(for: scheme, contrast: contrast)
    }

    public static let light = BadeTheme(scheme: .light)
    public static let dark = BadeTheme(scheme: .dark)

    /// The palette an appearance asks for. Anywhere the theme cannot be read from the environment
    /// — a widget's container background is extracted and drawn by the system, outside the view
    /// tree — this is how to arrive at the same answer rather than guessing at a default.
    public static func matching(
        _ scheme: ColorScheme, contrast: ColorSchemeContrast = .standard
    ) -> BadeTheme {
        switch (scheme, contrast) {
        case (.dark, .standard): .dark
        case (_, .standard): .light
        default: BadeTheme(scheme: scheme, contrast: contrast)
        }
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
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.environment(\.badeTheme, .matching(scheme, contrast: contrast))
    }
}
