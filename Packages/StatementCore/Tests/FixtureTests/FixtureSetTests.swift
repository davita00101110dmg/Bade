import Testing

@Suite("Synthetic fixture set")
struct FixtureSetTests {
    private static let formats = ["bog-en", "bog-ka", "tbc"]

    /// What the fixtures of each format must exercise between them.
    private static let requiredCases: Set<String> = [
        "georgian", "english", "mixed", "GEL", "USD", "EUR", "conversion", "refund", "reversal",
        "merchant-variants", "recurring", "one-off", "month-boundary", "year-boundary",
        "thousands", "decimal-comma", "empty-rows", "malformed-rows",
    ]

    @Test func everyStatementHasAnExpectation() {
        #expect(!StatementFixture.names.isEmpty)
        #expect(
            StatementFixture.files(endingIn: ".txt")
                == StatementFixture.files(endingIn: ".expected.json"))
    }

    @Test(arguments: formats)
    func everyFormatHasAtLeastTenFixtures(_ format: String) {
        #expect(StatementFixture.names.count { StatementFixture.format(of: $0) == format } >= 10)
    }

    @Test(arguments: formats)
    func everyFormatCoversTheRequiredCases(_ format: String) throws {
        let covered = try StatementFixture.names
            .filter { StatementFixture.format(of: $0) == format }
            .flatMap { try StatementFixture($0).expected.covers }

        #expect(Self.requiredCases.subtracting(covered).sorted() == [])
    }

    @Test(arguments: StatementFixture.names)
    func declaresOnlyKnownCases(_ name: String) throws {
        let covers = Set(try StatementFixture(name).expected.covers)

        #expect(covers.subtracting(Self.requiredCases).sorted() == [])
    }

    /// The repository is public: every account is a `GE00TEST` one and every card number is zeros.
    @Test(arguments: StatementFixture.names)
    func namesNoRealAccountOrCard(_ name: String) throws {
        let text = try StatementFixture(name).text
        let accounts = text.matches(of: /GE[0-9]{2}[A-Z0-9]{14,20}/).map { String($0.output) }
        let cards = text.matches(of: /[0-9]*\*{4,}[0-9]{4}/).map { String($0.output) }

        #expect(accounts.allSatisfy { $0.hasPrefix("GE00TEST") }, "\(accounts)")
        #expect(cards.allSatisfy { $0.allSatisfy { $0 == "0" || $0 == "*" } }, "\(cards)")
    }
}
