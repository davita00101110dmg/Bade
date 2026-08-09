import Foundation
import Testing

@testable import Core

private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}

private func makeRawTransaction(
    amount: Decimal = Decimal(string: "35.99")!,
    currency: String = "GEL"
) -> RawTransaction {
    RawTransaction(
        date: Date(timeIntervalSince1970: 1_754_697_600),
        rawDescription: "SP NETFLIX.COM 1082 LOS GATOS CA 4829",
        amount: amount,
        currency: currency,
        sourceLine: "09.08.2026  SP NETFLIX.COM 1082 LOS GATOS CA 4829  35.99 GEL"
    )
}

@Test func rawTransactionRoundTrips() throws {
    let value = makeRawTransaction()
    #expect(try roundTrip(value) == value)
}

@Test func normalizedTransactionRoundTrips() throws {
    let value = NormalizedTransaction(
        raw: makeRawTransaction(),
        merchant: "Netflix",
        merchantConfidence: 0.93
    )
    #expect(try roundTrip(value) == value)
}

@Test func priceChangeRoundTrips() throws {
    let value = PriceChange(
        date: Date(timeIntervalSince1970: 1_754_697_600),
        from: Decimal(string: "29.99")!,
        to: Decimal(string: "35.99")!
    )
    #expect(try roundTrip(value) == value)
}

@Test(arguments: Cadence.allCases)
func cadenceRoundTrips(cadence: Cadence) throws {
    #expect(try roundTrip(cadence) == cadence)
}

@Test(arguments: [Confidence.confident, .probable, .uncertain])
func confidenceRoundTrips(confidence: Confidence) throws {
    #expect(try roundTrip(confidence) == confidence)
}

@Test func detectedSubscriptionRoundTrips() throws {
    let value = DetectedSubscription(
        merchant: "Netflix",
        amount: Decimal(string: "35.99")!,
        currency: "GEL",
        cadence: .monthly,
        occurrences: [makeRawTransaction(), makeRawTransaction(amount: Decimal(string: "29.99")!)],
        nextChargeDate: Date(timeIntervalSince1970: 1_757_376_000),
        confidence: .confident,
        priceChanges: [
            PriceChange(
                date: Date(timeIntervalSince1970: 1_754_697_600),
                from: Decimal(string: "29.99")!,
                to: Decimal(string: "35.99")!
            )
        ]
    )
    #expect(try roundTrip(value) == value)
}

@Test func detectedSubscriptionRoundTripsWithEmptyArrays() throws {
    let value = DetectedSubscription(
        merchant: "Spotify",
        amount: Decimal(string: "14.99")!,
        currency: "USD",
        cadence: .annual,
        occurrences: [],
        nextChargeDate: Date(timeIntervalSince1970: 1_757_376_000),
        confidence: .uncertain,
        priceChanges: []
    )

    let decoded = try roundTrip(value)
    #expect(decoded == value)
    #expect(decoded.occurrences.isEmpty)
    #expect(decoded.priceChanges.isEmpty)
}

/// Money must survive JSON without floating-point drift — see spec §14.3.
@Test(arguments: ["0", "0.01", "35.99", "1234.5678", "0.1", "99999999.99", "12345678901234567.89"])
func decimalAmountsSurviveRoundTripExactly(literal: String) throws {
    let amount = Decimal(string: literal)!
    let decoded = try roundTrip(makeRawTransaction(amount: amount))
    #expect(decoded.amount == amount)
    #expect("\(decoded.amount)" == "\(amount)")
}
