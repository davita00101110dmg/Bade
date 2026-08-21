import SwiftUI

/// A colour for a merchant, derived from its name rather than stored anywhere. Bade cannot know
/// what colour a brand is — the statement says "SP NETFLIX REF001" and nothing more — but it can
/// give every merchant a face of its own, and the same one every time.
///
/// Takes a name already folded by whatever folds names for matching, so "NETFLIX" and "Netflix.com"
/// are one merchant with one colour. This module deals in primitives and does not know what a
/// merchant is; the caller that does knows how to fold one.
///
/// Only the hue comes from the name. Saturation and brightness are fixed, so whatever the name, the
/// colour lands inside the palette's family and can never clash with it.
public enum BadeMerchantColour {
    public static func hue(forFolded folded: String) -> Double {
        guard !folded.isEmpty else { return 0 }
        return Double(fingerprint(of: folded) % 360) / 360
    }

    /// Swift's own hashing is seeded per process, so the same merchant would change colour on every
    /// launch. This one does not move.
    private static func fingerprint(of folded: String) -> Int {
        folded.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 1_000_003 }
    }
}

extension Color {
    /// The merchant's own colour, at the weight a letter wants.
    public static func badeMerchant(folded: String) -> Color {
        Color(
            hue: BadeMerchantColour.hue(forFolded: folded),
            saturation: BadeMerchantMetrics.saturation,
            brightness: BadeMerchantMetrics.brightness)
    }
}

/// The colour's own numbers. Muted on purpose: thirty of these appear in one list, and a column of
/// fully saturated tiles is a paint chart rather than a list of subscriptions.
public enum BadeMerchantMetrics {
    public static let saturation = 0.42
    public static let brightness = 0.62
    /// How much of it is left in the tile behind the letter.
    public static let tintOpacity = 0.16
}
