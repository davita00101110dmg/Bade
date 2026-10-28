import Foundation
import Testing

@testable import StatementCore

private let parsers: [any StatementParser] = [BOGStatementParser(), TBCStatementParser()]
private let normalizer = MerchantNormalizer(directory: BundledCatalog())
private let analyzer = StatementAnalyzer()

/// Every synthetic statement, end to end: which parser claims it, every transaction it yields and
/// the merchant each resolves to, the exchange rates it records, and what detection makes of it.
@Suite("Synthetic statement fixtures")
struct StatementFixtureTests {
    /// Exactly one parser, or none: two banks claiming one file would make the choice an accident
    /// of array order.
    @Test(arguments: StatementFixture.names)
    func claimsTheExpectedParser(_ name: String) throws {
        let fixture = try StatementFixture(name)
        let claimed = parsers.filter { $0.canParse(fixture.text) }.map { type(of: $0).identifier }

        #expect(claimed == [fixture.expected.parser].compactMap(\.self))
    }

    @Test(arguments: StatementFixture.names)
    func readsEveryTransactionAndItsMerchant(_ name: String) throws {
        let fixture = try StatementFixture(name)
        let parser = parsers.first { $0.canParse(fixture.text) }
        let parsed = parser.flatMap { try? $0.parse(fixture.text) } ?? []

        expectRows(
            normalizer.normalize(parsed).map(TransactionRow.init),
            try fixture.expected.transactions.map(TransactionRow.init))
    }

    /// A merchant the catalog resolved carries full confidence, and only then.
    @Test(arguments: StatementFixture.names)
    func resolvesCatalogMerchantsWithFullConfidence(_ name: String) throws {
        let fixture = try StatementFixture(name)
        let parser = parsers.first { $0.canParse(fixture.text) }
        let normalized = normalizer.normalize(parser.flatMap { try? $0.parse(fixture.text) } ?? [])
        let brands = Set(MerchantSeed.entries.map(\.merchant))

        for transaction in normalized {
            #expect(
                (transaction.merchantConfidence == 1) == brands.contains(transaction.merchant),
                "\(transaction.merchant)")
        }
    }

    @Test(arguments: StatementFixture.names)
    func readsEveryExchangeRate(_ name: String) throws {
        let fixture = try StatementFixture(name)
        let parser = parsers.first { $0.canParse(fixture.text) }

        expectRows(
            (parser?.exchangeRates(in: fixture.text) ?? []).map(RateRow.init),
            try fixture.expected.rates.map(RateRow.init))
    }

    @Test(arguments: StatementFixture.names)
    func detectsTheExpectedSubscriptions(_ name: String) throws {
        let fixture = try StatementFixture(name)
        if let error = fixture.expected.error {
            #expect(throws: error) { try analyzer.analyse(text: fixture.text) }
            return
        }
        let result = try analyzer.analyse(text: fixture.text)

        #expect(result.transactionCount == fixture.expected.transactions.count)
        expectRows(
            result.detected.map(SubscriptionRow.init),
            try fixture.expected.subscriptions.map(SubscriptionRow.init))
        expectRows(
            result.candidates.map(CandidateRow.init),
            try fixture.expected.candidates.map(CandidateRow.init))
    }
}

/// Element by element, so a failure names the row rather than dumping two whole arrays.
private func expectRows<Row: Equatable>(
    _ actual: [Row], _ expected: [Row], sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(actual.count == expected.count, "row count", sourceLocation: sourceLocation)
    for (index, pair) in zip(actual, expected).enumerated() {
        #expect(pair.0 == pair.1, "row \(index + 1)", sourceLocation: sourceLocation)
    }
}

private struct TransactionRow: Equatable {
    let date: String
    let description: String
    let amount: Decimal
    let currency: String
    let mcc: String?
    let merchant: String
    let conversion: ConversionRow?

    init(_ actual: NormalizedTransaction) {
        date = day(actual.raw.date)
        description = actual.raw.rawDescription
        amount = actual.raw.amount
        currency = actual.raw.currency
        mcc = actual.raw.mcc
        merchant = actual.merchant
        conversion = actual.raw.conversion.map {
            ConversionRow(from: $0.from, to: $0.to, bankRate: $0.bankRate, schemeRate: $0.schemeRate)
        }
    }

    init(_ expected: FixtureExpectation.Transaction) throws {
        date = expected.date
        description = expected.description
        amount = try decimal(expected.amount)
        currency = expected.currency
        mcc = expected.mcc
        merchant = expected.merchant
        conversion = try expected.conversion.map {
            ConversionRow(
                from: $0.from, to: $0.to, bankRate: try decimal($0.bankRate),
                schemeRate: try $0.schemeRate.map(decimal))
        }
    }
}

private struct ConversionRow: Equatable {
    let from: String
    let to: String
    let bankRate: Decimal
    let schemeRate: Decimal?
}

/// Derived by division, so a rate is compared to six places rather than exactly.
private struct RateRow: Equatable {
    let date: String
    let from: String
    let to: String
    let rate: Decimal

    init(_ actual: ObservedRate) {
        date = day(actual.date)
        from = actual.from
        to = actual.to
        rate = rounded(actual.rate)
    }

    init(_ expected: FixtureExpectation.Rate) throws {
        date = expected.date
        from = expected.from
        to = expected.to
        rate = rounded(try decimal(expected.rate))
    }
}

private struct SubscriptionRow: Equatable {
    let merchant: String
    let currency: String
    let cadence: Cadence
    let amount: Decimal
    let charges: Int
    let confidence: Confidence
    let variable: Bool
    let ended: Bool
    let next: String
    let priceChanges: [PriceChangeRow]

    init(_ actual: DetectedSubscription) {
        merchant = actual.merchant
        currency = actual.currency
        cadence = actual.cadence
        amount = actual.amount
        charges = actual.occurrences.count
        confidence = actual.confidence
        variable = actual.isVariableAmount
        ended = actual.hasEnded
        next = day(actual.nextChargeDate)
        priceChanges = actual.priceChanges.map {
            PriceChangeRow(date: day($0.date), from: $0.from, to: $0.to)
        }
    }

    init(_ expected: FixtureExpectation.Subscription) throws {
        merchant = expected.merchant
        currency = expected.currency
        cadence = expected.cadence
        amount = try decimal(expected.amount)
        charges = expected.charges
        confidence = expected.confidence
        variable = expected.variable
        ended = expected.ended
        next = expected.next
        priceChanges = try expected.priceChanges.map {
            PriceChangeRow(date: $0.date, from: try decimal($0.from), to: try decimal($0.to))
        }
    }
}

private struct PriceChangeRow: Equatable {
    let date: String
    let from: Decimal
    let to: Decimal
}

private struct CandidateRow: Equatable {
    let merchant: String
    let currency: String
    let amount: Decimal
    let charges: Int

    init(_ actual: RepeatCandidate) {
        merchant = actual.merchant
        currency = actual.currency
        amount = actual.amount
        charges = actual.occurrences.count
    }

    init(_ expected: FixtureExpectation.Candidate) throws {
        merchant = expected.merchant
        currency = expected.currency
        amount = try decimal(expected.amount)
        charges = expected.charges
    }
}

private struct MalformedExpectation: Error {
    let value: String
}

private func decimal(_ text: String) throws -> Decimal {
    guard let value = Decimal(string: text) else { throw MalformedExpectation(value: text) }
    return value
}

private func rounded(_ value: Decimal) -> Decimal {
    var input = value
    var output = Decimal()
    NSDecimalRound(&output, &input, 6, .plain)
    return output
}

private func day(_ date: Date) -> String {
    let parts = Calendar.bade.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
}
