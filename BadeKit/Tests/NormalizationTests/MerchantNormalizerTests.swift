import Core
import Foundation
import Testing

@testable import Normalization

private func raw(_ description: String) -> RawTransaction {
    RawTransaction(
        date: Date(timeIntervalSince1970: 0), rawDescription: description,
        amount: 10, currency: "GEL", sourceLine: description)
}

/// Stands in for Catalog, which Normalization must not import.
private struct StubDirectory: MerchantDirectory {
    let entries: [String: String]
    func canonicalMerchant(for description: String) -> String? {
        entries[description.lowercased()]
    }
}

@Suite("Tier-1 cleaning")
struct MerchantCleaningTests {
    private let normalizer = MerchantNormalizer()

    private func clean(_ description: String) -> String {
        normalizer.normalize(raw(description)).merchant
    }

    @Test(arguments: [
        ("Wolt, Tbilisi, 61 Agmashenebeli ave. Tbilisi Georgia", "Wolt"),
        ("SETANTA.COM, United Kingdom of Great Britain and Northern Ireland", "SETANTA"),
        ("APPLE.COM/BILL, Ireland", "APPLE"),
        ("Amazon.com*SU6527FV3, United States of America", "Amazon"),
        ("Epidemic Sound, Sweden", "Epidemic Sound"),
        ("ori nabiji, Tbilisi, 22, chondideli st", "ori nabiji"),
    ])
    func stripsLocationTail(input: String, expected: String) {
        #expect(clean(input) == expected)
    }

    @Test(arguments: [
        ("FLT*MAGTICOM, Georgia", "MAGTICOM"),
        ("GOOGLE *YouTubePremium, United States of America", "YouTubePremium"),
        ("AMZ*Adobe, United States of America", "Adobe"),
    ])
    func stripsProcessorPrefixes(input: String, expected: String) {
        #expect(clean(input) == expected)
    }

    /// The whole reason Spotify was invisible: a different reference on every charge.
    @Test(arguments: ["P42A20", "P43B78", "P44C5B"])
    func collapsesPerChargeReferences(reference: String) {
        let description = "PAYPAL *SPOTIFY*\(reference), United Kingdom of Great Britain"
        #expect(clean(description) == "SPOTIFY")
    }

    /// The merchant is the name before the reference, not the processor prefix.
    @Test func keepsMerchantWhenOnlyTheReferenceIsAppended() {
        #expect(clean("AMAZON MKTPL*AD7CP6W13, United States of America") == "AMAZON MKTPL")
    }

    @Test func leavesWordsThatOnlyLookLikeReferences() {
        #expect(clean("FLT*MAGTICOM, Georgia") == "MAGTICOM")
        #expect(clean("TBC_P2P, Georgia") == "TBC_P2P")
    }

    @Test func neverReturnsAnEmptyMerchant() {
        #expect(clean("PAYPAL *") == "PAYPAL *")
        #expect(clean(", Tbilisi") == ", Tbilisi")
    }
}

@Suite("Catalog resolution")
struct CatalogResolutionTests {
    private let normalizer = MerchantNormalizer(
        directory: StubDirectory(entries: ["spotify": "Spotify", "magticom": "Magti"]))

    @Test func resolvesCleanedNamesToCanonicalBrands() {
        let result = normalizer.normalize(raw("PAYPAL *SPOTIFY*P42A20, United Kingdom"))
        #expect(result.merchant == "Spotify")
        #expect(result.merchantConfidence == 1.0)
    }

    @Test func allThreeSpotifyVariantsResolveToOneMerchant() {
        let merchants = ["P42A20", "P43B78", "P44C5B"].map {
            normalizer.normalize(raw("PAYPAL *SPOTIFY*\($0), United Kingdom")).merchant
        }
        #expect(Set(merchants) == ["Spotify"])
    }

    @Test func cleanedButUnknownMerchantsKeepLowerConfidence() {
        let result = normalizer.normalize(raw("Epidemic Sound, Sweden"))
        #expect(result.merchant == "Epidemic Sound")
        #expect(result.merchantConfidence == 0.6)
    }

    @Test func untouchedDescriptionsGetTheLowestConfidence() {
        let result = normalizer.normalize(raw("TBC_P2P"))
        #expect(result.merchantConfidence == 0.3)
    }

    /// §6: tier 1 alone must produce a working app with no LLM anywhere in the process.
    @Test func worksWithNoDirectoryAtAll() {
        let result = MerchantNormalizer().normalize(raw("GOOGLE *YouTubePremium, United States"))
        #expect(result.merchant == "YouTubePremium")
        #expect(result.raw.amount == 10)
    }
}
