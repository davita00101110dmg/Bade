import Core
import Foundation
import Testing

@testable import TestSupport

private func loadFixture() throws -> GoldenFixture {
    try GoldenFixture(name: "sample-statement-01", statementExtension: "csv")
}

/// What Normalization will eventually do (step 6); hardcoded here so one stub run can match.
private func knownMerchant(_ rawDescription: String) -> String {
    if rawDescription.hasPrefix("SP NETFLIX") { return "Netflix" }
    if rawDescription.hasPrefix("SPOTIFY") { return "Spotify" }
    return rawDescription
}

@Test func fixtureLoadsStatementAndExpectation() throws {
    let fixture = try loadFixture()

    #expect(!fixture.statement.isEmpty)
    #expect(fixture.expected.map(\.merchant) == ["Netflix", "Spotify"])
    #expect(fixture.expected[0].amount == Decimal(string: "35.99")!)
    #expect(fixture.expected[0].cadence == .monthly)
    #expect(fixture.expected[0].occurrences.count == 3)
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    #expect(
        utc.dateComponents([.year, .month, .day], from: fixture.expected[0].nextChargeDate)
            == DateComponents(year: 2026, month: 8, day: 9)
    )
}

/// The step-2 verification criterion: the harness must fail against a stub parser.
@Test func harnessRejectsStubParserOutput() throws {
    let fixture = try loadFixture()
    let comparison = compareGolden(
        actual: StubPipeline.run(fixture.statement),
        expected: fixture.expected
    )

    #expect(!comparison.matches)
    #expect(comparison.missing.map(\.merchant) == ["Netflix", "Spotify"])
    #expect(comparison.unexpected.count == 2)

    let message = try #require(comparison.failureMessage)
    #expect(message.contains("missing 2 expected subscription(s)"))
    #expect(message.contains("Netflix 35.99 GEL monthly ×3 next 2026-08-09 (confident)"))
    #expect(message.contains("SP NETFLIX.COM 1082 LOS GATOS CA 4829"))
}

@Test func harnessAcceptsMatchingOutput() throws {
    let fixture = try loadFixture()
    let actual = StubPipeline.run(fixture.statement, resolveMerchant: knownMerchant)

    let comparison = compareGolden(actual: actual, expected: fixture.expected)
    #expect(comparison.matches)
    #expect(comparison.failureMessage == nil)

    expectGolden(actual, matches: fixture)  // records no issue, or this test fails
}

@Test func comparisonIgnoresOrder() throws {
    let fixture = try loadFixture()
    let actual = StubPipeline.run(fixture.statement, resolveMerchant: knownMerchant).reversed()

    #expect(compareGolden(actual: Array(actual), expected: fixture.expected).matches)
}

@Test func comparisonTreatsDuplicatesAsSignificant() throws {
    let fixture = try loadFixture()
    let doubled = StubPipeline.run(fixture.statement, resolveMerchant: knownMerchant)
    let comparison = compareGolden(actual: doubled + doubled, expected: fixture.expected)

    #expect(!comparison.matches)
    #expect(comparison.missing.isEmpty)
    #expect(comparison.unexpected.map(\.merchant) == ["Netflix", "Spotify"])
}

@Test func comparisonReportsMissingWhenPipelineFindsNothing() throws {
    let fixture = try loadFixture()
    let comparison = compareGolden(actual: [], expected: fixture.expected)

    #expect(comparison.missing.count == 2)
    #expect(comparison.unexpected.isEmpty)
    #expect(comparison.failureMessage?.contains("produced") == false)
}

@Test func emptyOnBothSidesMatches() {
    let comparison = compareGolden(actual: [], expected: [])

    #expect(comparison.matches)
    #expect(comparison.failureMessage == nil)
}
