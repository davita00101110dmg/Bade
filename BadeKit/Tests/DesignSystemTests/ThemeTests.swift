import SwiftUI
import Testing

@testable import DesignSystem

/// WCAG 2.1 relative luminance and contrast ratio, computed from the palette's raw values.
private func luminance(_ rgb: UInt32) -> Double {
    let channels = [(rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF].map { component -> Double in
        let value = Double(component) / 255
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
}

private func contrast(_ a: UInt32, _ b: UInt32) -> Double {
    let (high, low) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
    return (high + 0.05) / (low + 0.05)
}

@Suite("Palette contrast")
struct PaletteContrastTests {
    private let surfaces: [(String, BadeColorPair)] = [
        ("surface", BadePalette.surface), ("raised", BadePalette.surfaceRaised),
    ]

    /// WCAG AA body text needs 4.5:1.
    @Test func bodyInkPassesAAOnEverySurface() {
        for (name, surface) in surfaces {
            #expect(contrast(BadePalette.ink.light, surface.light) >= 4.5, "ink on \(name) light")
            #expect(contrast(BadePalette.ink.dark, surface.dark) >= 4.5, "ink on \(name) dark")
        }
    }

    @Test func mutedInkPassesAA() {
        #expect(contrast(BadePalette.inkMuted.light, BadePalette.surface.light) >= 4.5)
        #expect(contrast(BadePalette.inkMuted.dark, BadePalette.surface.dark) >= 4.5)
    }

    /// Accent is used for links and labels, so it carries meaning and must pass AA too.
    @Test func accentPassesAA() {
        #expect(contrast(BadePalette.accent.light, BadePalette.surface.light) >= 4.5)
        #expect(contrast(BadePalette.accent.dark, BadePalette.surface.dark) >= 4.5)
    }

    /// The semantic colours carry words too — a price rise, a total that could not be converted —
    /// and this suite never checked them. `warning` had sat at 3.60:1 on a 13pt caption since the
    /// palette was written, which is how the only colour that never passed went unnoticed.
    @Test(arguments: [
        ("warning", BadePalette.warning), ("destructive", BadePalette.destructive),
        ("positive", BadePalette.positive),
    ])
    func semanticColoursPassAAOnEverySurface(_ name: String, _ pair: BadeColorPair) {
        for (surfaceName, surface) in surfaces {
            let light = contrast(pair.light, surface.light)
            let dark = contrast(pair.dark, surface.dark)
            #expect(light >= 4.5, "\(name) on \(surfaceName) light is \(light)")
            #expect(dark >= 4.5, "\(name) on \(surfaceName) dark is \(dark)")
        }
    }

    /// Faint ink is only ever used for large or non-essential text, so AA-large (3:1) applies.
    @Test func faintInkPassesAALarge() {
        #expect(contrast(BadePalette.inkFaint.light, BadePalette.surface.light) >= 3.0)
        #expect(contrast(BadePalette.inkFaint.dark, BadePalette.surface.dark) >= 3.0)
    }
}

@Suite("Palette under Increase Contrast")
struct IncreasedContrastTests {
    /// The targets the raised values were solved for, rather than picked by eye. Text goes to AAA,
    /// with the muted step above the faint one so raising the palette does not flatten the ink
    /// hierarchy into one grey. Borders carry no text and take the 3:1 asked of a boundary.
    private static let targets: [(String, BadeColorPair, Double)] = [
        ("ink", BadePalette.ink, 7.0),
        ("inkMuted", BadePalette.inkMuted, 8.5),
        ("inkFaint", BadePalette.inkFaint, 7.0),
        ("accent", BadePalette.accent, 7.0),
        ("accentPressed", BadePalette.accentPressed, 8.5),
        ("positive", BadePalette.positive, 7.0),
        ("warning", BadePalette.warning, 7.0),
        ("destructive", BadePalette.destructive, 7.0),
        ("border", BadePalette.border, 3.0),
    ]

    @Test(arguments: targets)
    func paletteMeetsItsContrastTargets(_ name: String, _ pair: BadeColorPair, _ target: Double) {
        let light = contrast(pair.lightIncreased, BadePalette.surface.lightIncreased)
        let dark = contrast(pair.darkIncreased, BadePalette.surface.darkIncreased)

        #expect(light >= target, "\(name) light is \(light), wanted \(target)")
        #expect(dark >= target, "\(name) dark is \(dark), wanted \(target)")
    }

    /// Raising contrast may never lower it. Trivially true today, and the thing most likely to
    /// break the next time somebody retunes one value and forgets its pair.
    @Test(arguments: targets)
    func raisingNeverWeakensAcolour(_ name: String, _ pair: BadeColorPair, _: Double) {
        let surface = BadePalette.surface

        #expect(
            contrast(pair.lightIncreased, surface.lightIncreased)
                >= contrast(pair.light, surface.light), "\(name) light got weaker")
        #expect(
            contrast(pair.darkIncreased, surface.darkIncreased)
                >= contrast(pair.dark, surface.dark), "\(name) dark got weaker")
    }

    /// Standard contrast has to keep resolving to the standard values — the whole change is opt-in,
    /// and a theme that quietly rendered the raised palette to everybody would be invisible here
    /// and obvious on a phone.
    @Test func standardContrastIsUntouched() {
        #expect(BadePalette.ink.value(for: .light, contrast: .standard) == BadePalette.ink.light)
        #expect(BadePalette.ink.value(for: .dark, contrast: .standard) == BadePalette.ink.dark)
        #expect(BadeTheme.matching(.light, contrast: .standard) == .light)
        #expect(BadeTheme.matching(.dark, contrast: .standard) == .dark)
    }

    @Test func increasedContrastResolvesToTheRaisedValues() {
        #expect(
            BadePalette.warning.value(for: .light, contrast: .increased)
                == BadePalette.warning.lightIncreased)
        #expect(BadeTheme.matching(.light, contrast: .increased) != .light)
        #expect(BadeTheme.matching(.dark, contrast: .increased) != .dark)
    }

    /// The decorative mesh sits *behind* text, so raising it would lower the contrast of everything
    /// drawn on top. It is the one token deliberately left alone.
    @Test func theNetIsNotRaised() {
        #expect(BadePalette.net.lightIncreased == BadePalette.net.light)
        #expect(BadePalette.net.darkIncreased == BadePalette.net.dark)
    }
}

@Suite("Theme")
struct ThemeTests {
    /// Compares raw values, not resolved Colors — Color equality needs a display context.
    @Test func everyTokenHasADistinctDarkValue() {
        let pairs: [(String, BadeColorPair)] = [
            ("surface", BadePalette.surface), ("ink", BadePalette.ink),
            ("inkMuted", BadePalette.inkMuted), ("inkFaint", BadePalette.inkFaint),
            ("accent", BadePalette.accent), ("border", BadePalette.border),
        ]
        for (name, pair) in pairs {
            #expect(pair.light != pair.dark, "\(name) has no dark variant")
        }
    }

    @Test func typographyFollowsTheConfiguredFamily() {
        #expect(BadeTypography.family == .system)
        #expect(BadeTypography.totalSize > BadeTypography.titleSize)
    }
}
