import SwiftUI

/// A colour in both appearances, as 0xRRGGBB, and what it becomes under Increase Contrast.
///
/// The raised values default to the standard ones, so a colour states a second pair only where
/// raising it is a deliberate choice — the surfaces and the decorative net do not move.
public struct BadeColorPair: Sendable, Equatable {
    public let light: UInt32
    public let dark: UInt32
    public let lightIncreased: UInt32
    public let darkIncreased: UInt32

    public init(
        light: UInt32, dark: UInt32,
        lightIncreased: UInt32? = nil, darkIncreased: UInt32? = nil
    ) {
        self.light = light
        self.dark = dark
        self.lightIncreased = lightIncreased ?? light
        self.darkIncreased = darkIncreased ?? dark
    }

    public func value(for scheme: ColorScheme, contrast: ColorSchemeContrast) -> UInt32 {
        switch (scheme, contrast) {
        case (.dark, .increased): darkIncreased
        case (.dark, _): dark
        case (_, .increased): lightIncreased
        default: light
        }
    }

    public func color(for scheme: ColorScheme, contrast: ColorSchemeContrast = .standard) -> Color {
        Color(rgb: value(for: scheme, contrast: contrast))
    }
}

/// The only place raw colour values live. Edit here and every screen follows; no view names a hex.
///
/// The raised values were solved for a contrast ratio against `surface` rather than picked by eye,
/// and `paletteMeetsItsContrastTargets` holds them there. Text goes to 7:1 with the muted step
/// pulled to 8.5:1 so the ink hierarchy survives being raised, and borders — which carry no text —
/// go to the 3:1 asked of a meaningful boundary. Dark mode barely moves, because it was already
/// there; light mode is where the work is.
public enum BadePalette {
    public static let surface = BadeColorPair(light: 0xEF_EE_E9, dark: 0x0E_0F_0C)
    public static let surfaceRaised = BadeColorPair(light: 0xF7_F6_F3, dark: 0x17_18_14)
    public static let surfaceSunken = BadeColorPair(light: 0xE7_E5_DE, dark: 0x19_1A_16)

    public static let ink = BadeColorPair(
        light: 0x17_18_14, dark: 0xF2_F1_EC,
        lightIncreased: 0x0A_0A_09, darkIncreased: 0xFE_FE_FD)
    public static let inkMuted = BadeColorPair(
        light: 0x5E_61_57, dark: 0x8D_90_86,
        lightIncreased: 0x42_44_3D, darkIncreased: 0xAB_AE_A6)
    /// Darkened from the design's #8A8D82/#6B6E65, which measured 2.91:1 and 3.70:1 — below the
    /// 4.5:1 AA floor for the 11pt labels it carries.
    public static let inkFaint = BadeColorPair(
        light: 0x6B_6D_65, dark: 0x78_7C_72,
        lightIncreased: 0x4F_50_4B, darkIncreased: 0x9B_9D_96)

    public static let accent = BadeColorPair(
        light: 0x1F_6F_5C, dark: 0x4F_A9_8F,
        lightIncreased: 0x19_59_4A, darkIncreased: 0x54_AC_92)
    public static let accentPressed = BadeColorPair(
        light: 0x14_51_3F, dark: 0x6F_C4_AB, lightIncreased: 0x13_4C_3B)

    /// The one that changes most: a hairline at 1.09:1 is decoration, and under Increase Contrast a
    /// card's edge has to be a boundary somebody can actually see.
    public static let border = BadeColorPair(
        light: 0xE7_E5_DE, dark: 0x2A_2C_25,
        lightIncreased: 0x8B_89_85, darkIncreased: 0x5E_60_5A)
    /// Decorative, and behind text. Raising it would lower the contrast of everything drawn on top,
    /// so it deliberately stays where it is.
    public static let net = BadeColorPair(light: 0x0E_0F_0C, dark: 0xFF_FF_FF)

    public static let positive = BadeColorPair(
        light: 0x1F_6F_5C, dark: 0x4F_A9_8F,
        lightIncreased: 0x19_59_4A, darkIncreased: 0x54_AC_92)
    /// Light measured 3.60:1 — under the AA floor at *standard* contrast, and the worst colour in
    /// the palette. Raising it is the biggest single win here.
    public static let warning = BadeColorPair(
        light: 0xB4_6A_1E, dark: 0xE0_9A_4E, lightIncreased: 0x74_44_13)
    /// Losing something, and money going the wrong way: a delete, a price rise. The design's
    /// #E08060 for dark; darkened for light, where it would otherwise sit under the 4.5:1 floor.
    public static let destructive = BadeColorPair(
        light: 0xB4_48_2A, dark: 0xE0_80_60,
        lightIncreased: 0x87_36_20, darkIncreased: 0xE1_84_64)
}

extension Color {
    /// Pure SwiftUI — no UIKit anywhere in Bade.
    fileprivate init(rgb: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255)
    }
}
