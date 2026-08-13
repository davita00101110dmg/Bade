import Core
import Foundation
import Testing

@testable import Catalog

@Suite("Catalog matching")
struct BundledCatalogTests {
    private let catalog = BundledCatalog()

    @Test func matchesPublishedPricePoint() {
        let match = catalog.match(merchant: "Netflix", amount: Decimal(string: "17.99")!, currency: "USD")
        #expect(match == .pricePoint(cadence: .monthly))
    }

    @Test func matchesAnnualPricePoint() {
        let match = catalog.match(merchant: "Amazon Prime", amount: Decimal(string: "139.00")!, currency: "USD")
        #expect(match == .pricePoint(cadence: .annual))
    }

    @Test func tolerancePutsNearbyAmountsOnThePricePoint() {
        let match = catalog.match(merchant: "Netflix", amount: Decimal(string: "18.50")!, currency: "USD")
        #expect(match == .pricePoint(cadence: .monthly))
    }

    @Test func fallsBackToMerchantWhenAmountIsUnknown() {
        let match = catalog.match(merchant: "Netflix", amount: Decimal(string: "3.00")!, currency: "USD")
        #expect(match == .merchant(typicalCadence: .monthly))
    }

    @Test func doesNotMatchPriceInAnotherCurrency() {
        let match = catalog.match(merchant: "Netflix", amount: Decimal(string: "17.99")!, currency: "GEL")
        #expect(match == .merchant(typicalCadence: .monthly))
    }

    @Test func returnsNoneForUnknownMerchants() {
        let match = catalog.match(merchant: "Nikora Supermarket", amount: 12, currency: "GEL")
        #expect(match == .none)
    }

    @Test func returnsNoneForBlankMerchant() {
        #expect(catalog.match(merchant: "  ", amount: 12, currency: "GEL") == .none)
    }

    /// Normalization cleans descriptions before the catalog sees them, so matching is exact.
    @Test(arguments: ["NETFLIX", "netflix", "Netflix ", "net flix"])
    func matchesRegardlessOfCaseSpacingAndPunctuation(merchant: String) {
        #expect(catalog.entry(for: merchant)?.merchant == "Netflix")
    }

    /// Processors bolt extra words onto the brand. The brand is still there, as a whole word.
    @Test(arguments: [
        "NETFLIX.COM 1082", "NETFLIX INTERNATIONAL", "ANTHROPIC* CLAUDE SUB",
        "CLAUDE.AI SUBSCRIPTION",
    ])
    func matchesABrandCarryingExtraWords(merchant: String) {
        #expect(catalog.entry(for: merchant) != nil)
    }

    /// A word either is the brand or it is not.
    @Test(arguments: ["OPEN AIR", "NETFLIXY", "SPOTIFYING"])
    func doesNotMatchMerchantsThatMerelyContainABrand(merchant: String) {
        #expect(catalog.entry(for: merchant) == nil)
    }

    /// "ZOOMMER" is one word and it is not "zoom" — it is a Georgian electronics chain that now has
    /// an entry of its own. Containing a brand still must not resolve to it.
    @Test func doesNotMistakeALongerWordForTheBrandInsideIt() {
        #expect(catalog.entry(for: "ZOOMMER")?.merchant == "Zoommer")
        #expect(catalog.entry(for: "ZOOMMER")?.merchant != "Zoom")
    }

    @Test func matchesOnAlias() {
        #expect(catalog.entry(for: "OPENAI")?.merchant == "ChatGPT")
        #expect(catalog.entry(for: "office365")?.merchant == "Microsoft 365")
    }
}

@Suite("Seed data integrity")
struct MerchantSeedTests {
    @Test func seedsAroundOneHundredMerchants() {
        #expect(MerchantSeed.entries.count >= 100)
    }

    @Test func merchantNamesAreUnique() {
        let names = MerchantSeed.entries.map(\.merchant)
        #expect(Set(names).count == names.count)
    }

    @Test func matchTokensAreDistinctiveEnoughToAvoidCollisions() {
        for entry in MerchantSeed.entries {
            for token in entry.matchTokens {
                #expect(token.count >= 3, "\(entry.merchant) token '\(token)' is too short")
            }
        }
    }

    @Test func noEntryIsShadowedByAnEarlierOne() {
        let catalog = BundledCatalog()
        for entry in MerchantSeed.entries {
            #expect(catalog.entry(for: entry.merchant)?.merchant == entry.merchant)
        }
    }

    @Test func everyPriceIsPositiveAndCarriesACurrency() {
        for entry in MerchantSeed.entries {
            for price in entry.pricePoints {
                #expect(price.amount > 0, "\(entry.merchant) has a non-positive price")
                #expect(price.currency.count == 3, "\(entry.merchant) currency is not ISO 4217")
            }
        }
    }
}
