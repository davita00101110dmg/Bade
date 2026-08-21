import Testing

@testable import DesignSystem

@Suite("Merchant colour")
struct BadeMerchantColourTests {
    /// The property the whole idea rests on. Swift's own hashing is seeded per process, so anything
    /// simpler would repaint every subscription on every launch.
    @Test func aMerchantAlwaysGetsTheSameHue() {
        #expect(
            BadeMerchantColour.hue(forFolded: "netflix")
                == BadeMerchantColour.hue(forFolded: "netflix"))
    }

    /// Callers hand over a folded name, so the variants that match as one merchant colour as one.
    @Test func namesThatFoldTogetherColourTogether() {
        let hue = BadeMerchantColour.hue(forFolded: "netflix")

        #expect(BadeMerchantColour.hue(forFolded: "netflix") == hue)
        #expect(BadeMerchantColour.hue(forFolded: "spotify") != hue)
    }

    @Test(arguments: ["netflix", "spotify", "adobecreativecloud", "magticom", "setantasports", ""])
    func everyHueLandsOnTheWheel(folded: String) {
        let hue = BadeMerchantColour.hue(forFolded: folded)

        #expect(hue >= 0 && hue < 1)
    }

    /// Spread rather than clustered: a palette that answers with the same corner of the wheel for
    /// every name is a single colour with extra steps.
    @Test func differentMerchantsSpreadAcrossTheWheel() {
        let names = [
            "netflix", "spotify", "adobe", "magticom", "setanta", "youtube", "chatgpt", "wolt",
            "amazonprime", "googleone", "epidemicsound", "icloud",
        ]
        let quarters = Set(names.map { Int(BadeMerchantColour.hue(forFolded: $0) * 4) })

        #expect(quarters.count >= 3)
    }
}
