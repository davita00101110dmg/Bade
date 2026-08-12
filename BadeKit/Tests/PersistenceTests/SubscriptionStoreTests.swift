import Core
import Foundation
import Testing

@testable import Persistence

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

private func charge(_ merchant: String, _ iso: String, _ amount: String) -> RawTransaction {
    RawTransaction(
        date: day(iso), rawDescription: merchant, amount: Decimal(string: amount)!,
        currency: "GEL", sourceLine: "\(iso) \(merchant)", mcc: "5815")
}

private func detected(
    _ merchant: String, amount: String, dates: [String], next: String,
    cadence: Cadence = .monthly, confidence: Confidence = .confident,
    priceChanges: [PriceChange] = []
) -> DetectedSubscription {
    DetectedSubscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: "GEL", cadence: cadence,
        occurrences: dates.map { charge(merchant, $0, amount) }, nextChargeDate: day(next),
        confidence: confidence, priceChanges: priceChanges)
}

private func newStore() throws -> SubscriptionStore {
    SubscriptionStore(modelContainer: try SubscriptionStore.container(inMemory: true))
}

/// SwiftData containers are not safe to spin up concurrently; parallel execution segfaults.
@Suite("Subscription store", .serialized)
struct SubscriptionStoreTests {
    /// Step 7's criterion: confirm-and-save round-trips.
    @Test func confirmAndSaveRoundTrips() async throws {
        let store = try newStore()
        let spotify = detected(
            "Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20", "2026-07-20"],
            next: "2026-08-20")

        _ = try await store.confirm([spotify])
        let stored = try await store.all()

        #expect(stored.count == 1)
        #expect(stored[0].merchant == "Spotify")
        #expect(stored[0].amount == Decimal(string: "15.20")!)
        #expect(stored[0].cadence == .monthly)
        #expect(stored[0].occurrenceCount == 3)
        #expect(stored[0].firstChargeDate == day("2026-05-20"))
        #expect(stored[0].lastChargeDate == day("2026-07-20"))
        #expect(stored[0].nextChargeDate == day("2026-08-20"))
        #expect(stored[0].confidence == .confident)
        #expect(stored[0].isActive)
    }

    @Test func decimalAmountsSurvivePersistenceExactly() async throws {
        let store = try newStore()
        for amount in ["0.99", "15.20", "1234.5678", "99999999.99"] {
            _ = try await store.confirm([
                detected("M\(amount)", amount: amount, dates: ["2026-01-05", "2026-02-05"], next: "2026-03-05")
            ])
        }
        let stored = try await store.all()
        #expect(Set(stored.map(\.amount)) == Set(["0.99", "15.20", "1234.5678", "99999999.99"].map { Decimal(string: $0)! }))
    }

    @Test func priceChangesSurvivePersistence() async throws {
        let store = try newStore()
        let change = PriceChange(
            date: day("2026-06-27"), from: Decimal(string: "10.29")!, to: Decimal(string: "17.49")!)

        _ = try await store.confirm([
            detected(
                "YouTube Premium", amount: "17.49",
                dates: ["2026-05-27", "2026-06-27", "2026-07-28"], next: "2026-08-28",
                priceChanges: [change])
        ])

        #expect(try await store.all().first?.priceChanges == [change])
    }

    @Test func reimportingTheSameStatementDoesNotDuplicate() async throws {
        let store = try newStore()
        let spotify = detected(
            "Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")

        _ = try await store.confirm([spotify])
        _ = try await store.confirm([spotify])

        #expect(try await store.all().count == 1)
    }

    @Test func alaterImportExtendsTheHistoryAndMovesTheNextCharge() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])
        let firstID = try await store.all()[0].id

        _ = try await store.confirm([
            detected(
                "Spotify", amount: "15.90", dates: ["2026-06-20", "2026-07-20", "2026-08-20"],
                next: "2026-09-20")
        ])

        let stored = try await store.all()
        #expect(stored.count == 1)
        #expect(stored[0].id == firstID, "identity survives re-import")
        #expect(stored[0].amount == Decimal(string: "15.90")!)
        #expect(stored[0].firstChargeDate == day("2026-05-20"))
        #expect(stored[0].lastChargeDate == day("2026-08-20"))
        #expect(stored[0].nextChargeDate == day("2026-09-20"))
    }

    /// An older overlapping statement must not drag the subscription backwards.
    @Test func anOlderImportDoesNotRewindTheSubscription() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Spotify", amount: "15.90", dates: ["2026-07-20", "2026-08-20"], next: "2026-09-20")
        ])
        _ = try await store.confirm([
            detected("Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])

        let stored = try await store.all()
        #expect(stored.count == 1)
        #expect(stored[0].amount == Decimal(string: "15.90")!)
        #expect(stored[0].nextChargeDate == day("2026-09-20"))
        #expect(stored[0].firstChargeDate == day("2026-05-20"))
    }

    @Test func differentCadencesAtOneMerchantStaySeparate() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Apple", amount: "11.99", dates: ["2026-05-18", "2026-06-18"], next: "2026-07-18"),
            detected(
                "Apple", amount: "99.00", dates: ["2025-06-01", "2026-06-01"], next: "2027-06-01",
                cadence: .annual),
        ])
        #expect(try await store.all().count == 2)
    }

    @Test func deletesOneAndDeletesEverything() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20"),
            detected("Netflix", amount: "35.99", dates: ["2026-05-09", "2026-06-09"], next: "2026-07-09"),
        ])

        let first = try await store.all()[0]
        try await store.delete(id: first.id)
        #expect(try await store.all().count == 1)

        try await store.deleteAll()
        #expect(try await store.all().isEmpty)
    }

    @Test func editsToAStoredSubscriptionPersist() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])

        var stored = try await store.all()[0]
        stored.isActive = false
        stored.merchant = "Spotify Family"
        try await store.save(stored)

        let reloaded = try await store.all()
        #expect(reloaded.count == 1)
        #expect(reloaded[0].isActive == false)
        #expect(reloaded[0].merchant == "Spotify Family")
    }

    /// §10 requires export in v1.
    @Test func exportsJSONThatDecodesBack() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])

        let data = try await store.exportJSON()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([Subscription].self, from: data)

        #expect(decoded == (try await store.all()))
        #expect(String(decoding: data, as: UTF8.self).contains("Spotify"))
    }

    @Test func startsEmpty() async throws {
        #expect(try await newStore().all().isEmpty)
    }
}

/// One merchant billing several subscriptions at once is the case `matchKey` alone cannot see:
/// merchant, currency and cadence are identical, and only the amount tells them apart.
@Suite("Concurrent subscriptions from one merchant", .serialized)
struct ConcurrentSubscriptionTests {
    private func apple(_ amount: String, dates: [String] = ["2026-06-01", "2026-07-01"])
        -> DetectedSubscription
    {
        detected("Apple", amount: amount, dates: dates, next: "2026-08-01")
    }

    @Test func threeAppleSubscriptionsSaveAsThree() async throws {
        let store = try newStore()

        _ = try await store.confirm([apple("2.99"), apple("9.99"), apple("24.99")])

        let all = try await store.all()
        #expect(all.count == 3)
        #expect(Set(all.map(\.amount)) == [Decimal(string: "2.99")!, 9.99, 24.99])
    }

    @Test func reimportingThemMatchesEachToItsOwnRow() async throws {
        let store = try newStore()
        let batch = [apple("2.99"), apple("9.99"), apple("24.99")]

        _ = try await store.confirm(batch)
        _ = try await store.confirm(batch)

        #expect(try await store.all().count == 3)
    }

    @Test func aPriceRiseStillUpdatesRatherThanSplitting() async throws {
        let store = try newStore()
        _ = try await store.confirm([apple("2.99")])

        _ = try await store.confirm([apple("4.99")])

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all[0].amount == Decimal(string: "4.99")!)
    }

    @Test func aSecondSubscriptionAppearsWithoutDisturbingTheFirst() async throws {
        let store = try newStore()
        _ = try await store.confirm([apple("2.99")])

        _ = try await store.confirm([apple("2.99"), apple("24.99")])

        #expect(try await store.all().count == 2)
    }
}

/// A subscription typed in by hand has a price and a rhythm but no history, and the import that
/// finally finds it must recognise it rather than list it twice.
@Suite("Hand-entered subscriptions", .serialized)
struct HandEnteredSubscriptionTests {
    private func typed(
        _ merchant: String, amount: String, currency: String = "GEL", cadence: Cadence = .monthly
    ) -> Subscription {
        Subscription(
            merchant: merchant, amount: Decimal(string: amount)!, currency: currency,
            cadence: cadence, firstChargeDate: day("2026-06-20"), lastChargeDate: day("2026-06-20"),
            nextChargeDate: day("2026-07-20"), confidence: .confident)
    }

    @Test func oneWithNoChargesRoundTrips() async throws {
        let store = try newStore()

        try await store.save(typed("Netflix", amount: "35.99"))

        let stored = try #require(try await store.all().first)
        #expect(stored.charges.isEmpty)
        #expect(stored.occurrenceCount == 0)
        #expect(stored.amount == Decimal(string: "35.99")!)
    }

    @Test func alaterImportFindsItAndGivesItAHistory() async throws {
        let store = try newStore()
        let entered = typed("netflix ", amount: "35.99")
        try await store.save(entered)

        _ = try await store.confirm([
            detected("Netflix", amount: "35.99", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])

        let stored = try await store.all()
        #expect(stored.count == 1)
        #expect(stored[0].id == entered.id, "the row the user made is the row that survives")
        #expect(stored[0].charges.count == 2)
    }

    /// An import never renames a row underneath the user, however sloppily they typed it.
    @Test func theNameTheUserTypedSurvivesTheImport() async throws {
        let store = try newStore()
        try await store.save(typed("netflix", amount: "35.99"))

        _ = try await store.confirm([
            detected("Netflix", amount: "35.99", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])

        #expect(try await store.all().map(\.merchant) == ["netflix"])
    }

    /// The identity is set once, so renaming cannot hide a subscription from the next import.
    @Test func renamingKeepsItFindableByALaterImport() async throws {
        let store = try newStore()
        let batch = [
            detected("Spotify", amount: "15.20", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ]
        _ = try await store.confirm(batch)

        var stored = try await store.all()[0]
        stored.merchant = "Spotify Family"
        try await store.save(stored)
        _ = try await store.confirm(batch)

        let reloaded = try await store.all()
        #expect(reloaded.count == 1)
        #expect(reloaded[0].merchant == "Spotify Family")
    }

    @Test func aDifferentCadenceIsADifferentSubscription() async throws {
        let store = try newStore()
        try await store.save(typed("Netflix", amount: "35.99", cadence: .annual))

        _ = try await store.confirm([
            detected("Netflix", amount: "35.99", dates: ["2026-05-20", "2026-06-20"], next: "2026-07-20")
        ])

        #expect(try await store.all().count == 2)
    }
}

/// Detail's history, the price timeline and §8's markup all read the charges rather than a count,
/// so they have to outlive the import that found them.
@Suite("Stored charges", .serialized)
struct StoredChargeTests {
    @Test func chargesSurviveConfirmation() async throws {
        let store = try newStore()

        _ = try await store.confirm([
            detected("Netflix", amount: "35.99", dates: ["2026-06-01", "2026-07-01"], next: "2026-08-01")
        ])

        let stored = try #require(try await store.all().first)
        #expect(stored.charges.count == 2)
        #expect(stored.charges.map(\.amount) == [Decimal(string: "35.99")!, Decimal(string: "35.99")!])
        #expect(stored.occurrenceCount == 2)
    }

    @Test func reimportingTheSameStatementDoesNotDuplicateCharges() async throws {
        let store = try newStore()
        let batch = [
            detected("Netflix", amount: "35.99", dates: ["2026-06-01", "2026-07-01"], next: "2026-08-01")
        ]

        _ = try await store.confirm(batch)
        _ = try await store.confirm(batch)

        #expect(try await store.all().first?.charges.count == 2)
    }

    /// Two statements covering different months are two halves of one history.
    @Test func overlappingStatementsUnionIntoOneHistory() async throws {
        let store = try newStore()
        _ = try await store.confirm([
            detected("Netflix", amount: "35.99", dates: ["2026-05-01", "2026-06-01"], next: "2026-07-01")
        ])

        _ = try await store.confirm([
            detected("Netflix", amount: "35.99", dates: ["2026-06-01", "2026-07-01"], next: "2026-08-01")
        ])

        let stored = try #require(try await store.all().first)
        #expect(stored.charges.count == 3, "May, June and July, with June counted once")
        #expect(stored.charges.map(\.date) == stored.charges.map(\.date).sorted())
    }

    @Test func aChargeKeepsWhatTheBankDidToConvertIt() async throws {
        let store = try newStore()
        let conversion = CurrencyConversion(
            from: "USD", to: "GEL", bankRate: Decimal(string: "2.72")!,
            schemeRate: Decimal(string: "2.61")!)
        let charge = RawTransaction(
            date: day("2026-06-01"), rawDescription: "NETFLIX.COM", amount: Decimal(string: "12.99")!,
            currency: "USD", sourceLine: "x", conversion: conversion)
        let subscription = DetectedSubscription(
            merchant: "Netflix", amount: Decimal(string: "12.99")!, currency: "USD",
            cadence: .monthly, occurrences: [charge], nextChargeDate: day("2026-07-01"),
            confidence: .confident, priceChanges: [])

        _ = try await store.confirm([subscription])

        let stored = try #require(try await store.all().first?.charges.first)
        #expect(stored.conversion?.bankRate == Decimal(string: "2.72")!)
        #expect(stored.conversion?.markupFraction != nil)
    }
}
