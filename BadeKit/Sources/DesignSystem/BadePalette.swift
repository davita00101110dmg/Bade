import SwiftUI

/// A colour in both appearances, as 0xRRGGBB.
public struct BadeColorPair: Sendable, Equatable {
    public let light: UInt32
    public let dark: UInt32

    public init(light: UInt32, dark: UInt32) {
        self.light = light
        self.dark = dark
    }

    public func color(for scheme: ColorScheme) -> Color {
        Color(rgb: scheme == .dark ? dark : light)
    }
}

/// The only place raw colour values live. Edit here and every screen follows; no view names a hex.
public enum BadePalette {
    public static let surface = BadeColorPair(light: 0xEF_EE_E9, dark: 0x0E_0F_0C)
    public static let surfaceRaised = BadeColorPair(light: 0xF7_F6_F3, dark: 0x17_18_14)
    public static let surfaceSunken = BadeColorPair(light: 0xE7_E5_DE, dark: 0x19_1A_16)

    public static let ink = BadeColorPair(light: 0x17_18_14, dark: 0xF2_F1_EC)
    public static let inkMuted = BadeColorPair(light: 0x5E_61_57, dark: 0x8D_90_86)
    /// Darkened from the design's #8A8D82/#6B6E65, which measured 2.91:1 and 3.70:1 — below the
    /// 4.5:1 AA floor for the 11pt labels it carries.
    public static let inkFaint = BadeColorPair(light: 0x6B_6D_65, dark: 0x78_7C_72)

    public static let accent = BadeColorPair(light: 0x1F_6F_5C, dark: 0x4F_A9_8F)
    public static let accentPressed = BadeColorPair(light: 0x14_51_3F, dark: 0x6F_C4_AB)

    public static let border = BadeColorPair(light: 0xE7_E5_DE, dark: 0x2A_2C_25)
    public static let net = BadeColorPair(light: 0x0E_0F_0C, dark: 0xFF_FF_FF)

    public static let positive = BadeColorPair(light: 0x1F_6F_5C, dark: 0x4F_A9_8F)
    public static let warning = BadeColorPair(light: 0xB4_6A_1E, dark: 0xE0_9A_4E)
    /// Losing something, and money going the wrong way: a delete, a price rise. The design's
    /// #E08060 for dark; darkened for light, where it would otherwise sit under the 4.5:1 floor.
    public static let destructive = BadeColorPair(light: 0xB4_48_2A, dark: 0xE0_80_60)
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
