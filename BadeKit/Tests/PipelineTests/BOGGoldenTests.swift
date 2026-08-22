import Catalog
import Core
import Detection
import Foundation
import Ingestion
import Normalization
import TestSupport
import Testing

/// Real statement in, exact subscription set out (CLAUDE.md). Derived from a Bank of Georgia
/// export: every date, amount, currency, MCC and conversion rate is real, and every merchant the
/// catalog does not already ship was replaced before it came near the repository — as was the
/// branch address BOG appends to the ones it does.
///
/// This is the launch bank, and until this fixture existed its parser had no test that survived
/// leaving one laptop: the real statements are gitignored, so every BOG suite skipped everywhere
/// else, including CI.
@Suite("BOG golden fixture")
struct BOGGoldenTests {
    private let parser = BOGStatementParser()

    private func fixture() throws -> GoldenFixture {
        try GoldenFixture(name: "bog-statement-01", statementExtension: "txt")
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

    /// Card purchases and only card purchases: the file opens with an account header and the
    /// holder's own currency conversion, neither of which is a charge.
    @Test func parsesEveryPurchaseAndNothingElse() throws {
        let transactions = try parser.parse(statement(try fixture()))

        #expect(transactions.count == 326)
        #expect(transactions.allSatisfy { $0.amount > 0 })
        #expect(transactions.allSatisfy { !$0.rawDescription.isEmpty })
        #expect(Set(transactions.map(\.currency)) == ["GEL", "USD", "EUR"])
    }

    /// Both sides of every foreign charge, which is what §8's markup is measured from.
    @Test func keepsTheConversionPrintedBesideAForeignCharge() throws {
        let converted = try parser.parse(statement(try fixture())).compactMap(\.conversion)

        #expect(converted.count == 22)
        #expect(converted.allSatisfy { $0.bankRate > 0 })
        #expect(converted.contains { $0.schemeRate != nil })
    }

    /// The account holder's own conversion, which carries no merchant and is not a charge — and is
    /// the only place a rate appears when a charge settles from a balance already in its currency.
    @Test func readsTheAccountHoldersOwnConversion() throws {
        let rates = parser.exchangeRates(in: statement(try fixture()))

        #expect(rates.count == 1)
        #expect(rates[0].from == "USD")
        #expect(rates[0].to == "GEL")
        #expect(rates[0].rate == Decimal(string: "2.6716")!)
    }

    /// The failure real data exposed: PayPal appends its own reference to every charge, so one
    /// subscription arrived as three merchants. It was fixed long ago and only a local statement
    /// proved it; the three reference strings are in this fixture so it stays proved.
    @Test func collapsesTheThreePayPalSpotifyReferences() throws {
        let raw = try parser.parse(statement(try fixture())).map(\.rawDescription)
        let catalog = BundledCatalog()
        let detected = SubscriptionDetector(catalog: catalog)
            .detect(MerchantNormalizer(directory: catalog).normalize(try parser.parse(statement(try fixture()))))

        #expect(Set(raw.filter { $0.hasPrefix("PAYPAL *SPOTIFY") }).count == 3)
        #expect(detected.filter { $0.merchant == "Spotify" }.count == 1)
        #expect(detected.first { $0.merchant == "Spotify" }?.occurrences.count == 3)
    }

    /// The repository is public. A merchant here is either a brand the catalog already ships or a
    /// placeholder — never a name read off somebody's statement. Counted rather than named, so a
    /// failure does not print the thing it is complaining about.
    @Test func namesNoMerchantThatIsNotAlreadyPublic() throws {
        let catalog = BundledCatalog()
        let merchants = Set(try parser.parse(statement(try fixture())).map(\.rawDescription))
        let unknown = merchants.filter {
            !$0.hasPrefix("MERCHANT") && catalog.entry(for: $0) == nil
        }

        #expect(!merchants.isEmpty)
        #expect(unknown.isEmpty, "\(unknown.count) merchant strings are neither placeholder nor brand")
    }

    /// A branch address says where somebody shops, which a brand name does not. BOG appends either
    /// a country or a city and street; the second kind was trimmed when the fixture was built.
    @Test func namesNoBranchAddress() throws {
        let merchants = Set(try parser.parse(statement(try fixture())).map(\.rawDescription))
        let addressed = merchants.filter { merchant in
            guard !merchant.hasPrefix("MERCHANT"), let comma = merchant.firstIndex(of: ",") else {
                return false
            }
            return merchant[comma...].contains(where: \.isNumber)
        }

        #expect(addressed.isEmpty, "\(addressed.count) merchant strings still carry an address")
    }
}
