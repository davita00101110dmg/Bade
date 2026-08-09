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

    /// Faint ink is only ever used for large or non-essential text, so AA-large (3:1) applies.
    @Test func faintInkPassesAALarge() {
        #expect(contrast(BadePalette.inkFaint.light, BadePalette.surface.light) >= 3.0)
        #expect(contrast(BadePalette.inkFaint.dark, BadePalette.surface.dark) >= 3.0)
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
