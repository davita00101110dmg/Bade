import Core
import Testing

@testable import Catalog

@Suite("Merchant suggestions")
struct MerchantSuggestionTests {
    private let catalog = BundledCatalog()

    @Test func suggestsBrandsBeginningWithWhatWasTyped() {
        #expect(catalog.suggestedMerchants(matching: "netf") == ["Netflix"])
    }

    @Test func ignoresCaseSpacingAndPunctuation() {
        #expect(catalog.suggestedMerchants(matching: " You Tube.") == catalog.suggestedMerchants(matching: "youtube"))
    }

    @Test func offersAPrefixBeforeAMerelyContainedMatch() {
        let suggestions = catalog.suggestedMerchants(matching: "app")
        let apple = try? #require(suggestions.firstIndex(of: "Apple"))
        let snapchat = suggestions.firstIndex(of: "Snapchat")

        #expect(apple != nil)
        if let apple, let snapchat { #expect(apple < snapchat) }
    }

    @Test func staysShortEnoughToSitUnderTheField() {
        #expect(catalog.suggestedMerchants(matching: "a").count <= 5)
    }

    @Test func aNameTypedInFullSuggestsNothingFurther() {
        #expect(catalog.suggestedMerchants(matching: "Netflix").contains("Netflix") == false)
    }

    @Test func suggestsNothingForAnEmptyOrUnknownName() {
        #expect(catalog.suggestedMerchants(matching: "   ").isEmpty)
        #expect(catalog.suggestedMerchants(matching: "Nikora Supermarket").isEmpty)
    }

    /// An alias is how the statement writes it, not how the user does; the brand is what appears.
    @Test func aliasMatchesButTheBrandIsWhatIsOffered() {
        #expect(catalog.suggestedMerchants(matching: "disney+") == ["Disney Plus"])
    }
}
