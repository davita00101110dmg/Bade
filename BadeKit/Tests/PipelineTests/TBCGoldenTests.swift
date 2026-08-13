import Catalog
import Core
import Detection
import Foundation
import Ingestion
import Normalization
import TestSupport
import Testing

/// Real statement in, exact subscription set out (CLAUDE.md). The fixture was derived from a TBC
/// statement: its records, dates, amounts, currencies and MCCs are real; every merchant the
/// catalog does not already know was replaced before it came anywhere near the repository.
@Suite("TBC golden fixture")
struct TBCGoldenTests {
    private let parser = TBCStatementParser()

    private func fixture() throws -> GoldenFixture {
        try GoldenFixture(name: "tbc-statement-01", statementExtension: "txt")
    }

    private func statement(_ fixture: GoldenFixture) -> String {
        String(decoding: fixture.statement, as: UTF8.self)
    }

    @Test func producesExactlyTheExpectedSubscriptions() throws {
        let fixture = try fixture()
        let catalog = BundledCatalog()
        let detected = SubscriptionDetector(catalog: catalog)
            .detect(
                MerchantNormalizer(directory: catalog)
                    .normalize(try parser.parse(statement(fixture))))

        expectGolden(detected, matches: fixture)
    }

    /// Every card purchase and only card purchases: the fixture ends with a fee row and a transfer,
    /// and opens with a salary and a conversion, none of which are charges.
    @Test func parsesEveryCardPurchaseAndNothingElse() throws {
        let transactions = try parser.parse(statement(try fixture()))

        #expect(transactions.count == 770)
        #expect(transactions.allSatisfy { $0.mcc != nil })
        #expect(transactions.allSatisfy { $0.amount > 0 })
        #expect(Set(transactions.map(\.currency)) == ["GEL", "USD", "EUR"])
    }

    @Test func readsTheConversionRateTheStatementPrints() throws {
        let rates = parser.exchangeRates(in: statement(try fixture()))

        #expect(rates.count == 1)
        #expect(rates[0].from == "USD")
        #expect(rates[0].to == "GEL")
        #expect(rates[0].rate == Decimal(string: "2.71")!)
    }

    /// The repository is public. A merchant in this fixture is either a brand the catalog already
    /// ships or a placeholder — never a name read off somebody's statement. Counted, not named,
    /// so a failure does not print the thing it is complaining about.
    @Test func namesNoMerchantThatIsNotAlreadyPublic() throws {
        let catalog = BundledCatalog()
        let merchants = Set(try parser.parse(statement(try fixture())).map(\.rawDescription))
        let unknown = merchants.filter {
            !$0.hasPrefix("MERCHANT") && catalog.entry(for: $0) == nil
        }

        #expect(!merchants.isEmpty)
        #expect(unknown.isEmpty, "\(unknown.count) merchant strings are neither placeholder nor brand")
    }
}
