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
