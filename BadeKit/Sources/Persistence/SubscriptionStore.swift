import Core
import Foundation
import SwiftData

@ModelActor
public actor SubscriptionStore: SubscriptionRepository, RateRepository, OfficialRateStore {
    /// Every listener that wants to know when the subscriptions change.
    private var listeners: [AsyncStream<Void>.Continuation] = []

    /// Announces writes, so whatever is derived from the store — the widget's snapshot, the reminder
    /// schedule — is rebuilt without every screen that edits a row remembering to say so. A screen
    /// deep in a feature can delete a subscription; only the store sees all of them.
    public func changes() -> AsyncStream<Void> {
        AsyncStream { continuation in
            listeners.append(continuation)
        }
    }

    private func announce() {
        for listener in listeners { listener.yield() }
    }

    /// Where the store has always been, named rather than left to CoreData. Its default directory
    /// becomes the App Group container the moment an app has one, so adding the widget's entitlement
    /// silently moved the store and left every existing install's data behind it. Pinning the path
    /// makes the location a decision instead of a side effect.
    public static var storeURL: URL? {
        try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true
        )
        .appending(path: "default.store")
    }

    /// Local store only — no CloudKit, no remote container (§10). Versioned, so a schema change
    /// meets a migration plan rather than a phone that will not launch. `at` exists so the recovery
    /// path can be tested somewhere other than the real store.
    public static func container(inMemory: Bool = false, at url: URL? = nil) throws -> ModelContainer
    {
        let schema = Schema(versionedSchema: BadeSchemaV1.self)
        let configuration =
            if inMemory {
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            } else if let file = url ?? storeURL {
                ModelConfiguration(schema: schema, url: file)
            } else {
                ModelConfiguration(schema: schema)
            }
        return try ModelContainer(
            for: schema, migrationPlan: BadeMigrations.self, configurations: configuration)
    }

    /// The store, opened however it can be. What cannot be read is moved aside rather than deleted,
    /// because a manual entry is the one thing in Bade that no statement can produce again.
    public static func opened(at url: URL? = nil) -> OpenedStore {
        if let container = try? container(at: url) {
            return OpenedStore(store: SubscriptionStore(modelContainer: container), wasReset: false)
        }

        if let file = url ?? storeURL { setAside(file) }

        // The second attempt writes where nothing readable remains, so it fails only if the device
        // cannot store anything at all — and then memory is the only place left to work in.
        let container = (try? container(at: url)) ?? (try! container(inMemory: true))
        return OpenedStore(store: SubscriptionStore(modelContainer: container), wasReset: true)
    }

    /// Moved, never removed: a later version of Bade may be able to read what this one could not.
    private static func setAside(_ store: URL) {
        let manager = FileManager.default
        let stamp = ISO8601DateFormatter.string(
            from: .now, timeZone: .current, formatOptions: [.withFullDate])
        let destination = store.deletingLastPathComponent().appending(path: "Unreadable \(stamp)")
        try? manager.createDirectory(at: destination, withIntermediateDirectories: true)

        // SwiftData keeps its write-ahead log beside the store; all three have to travel together.
        for suffix in ["", "-shm", "-wal"] {
            let file = URL(filePath: store.path() + suffix)
            guard manager.fileExists(atPath: file.path()) else { continue }
            try? manager.moveItem(at: file, to: destination.appending(path: file.lastPathComponent))
        }
    }

    /// Only the days asked for: the store holds every day ever fetched, and a screen wants a few.
    public func officialRates(for currencies: Set<String>, on dates: Set<Date>) async throws
        -> [OfficialRate]
    {
        let days = Set(dates.map(\.timeIntervalSince1970))
        return try modelContext.fetch(FetchDescriptor<OfficialRateRecord>())
            .filter { currencies.contains($0.currency) && days.contains($0.date.timeIntervalSince1970) }
            .map(\.official)
    }

    public func record(_ rates: [OfficialRate]) async throws {
        let existing = Set(
            try modelContext.fetch(FetchDescriptor<OfficialRateRecord>()).map(\.identity))
        for rate in rates where !existing.contains(OfficialRateRecord.identity(of: rate)) {
            modelContext.insert(OfficialRateRecord(rate))
        }
        try modelContext.save()
    }

    public func observedRates() async throws -> RateBook {
        var book = RateBook()
        for record in try modelContext.fetch(FetchDescriptor<ObservedRateRecord>()) {
            book.record(record.observed)
        }
        return book
    }

    /// Rates accumulate across imports: a statement arriving later can carry the rate that finally
    /// converts a charge imported today.
    public func record(_ rates: RateBook) async throws {
        let existing = Set(
            try modelContext.fetch(FetchDescriptor<ObservedRateRecord>()).map(\.identity))
        for observed in rates.observations
        where !existing.contains(ObservedRateRecord.identity(of: observed)) {
            modelContext.insert(ObservedRateRecord(observed))
        }
        try modelContext.save()
    }

    public func all() async throws -> [Subscription] {
        try modelContext
            .fetch(FetchDescriptor<SubscriptionRecord>(sortBy: [SortDescriptor(\.merchant)]))
            .map(\.subscription)
    }

    public func save(_ subscription: Subscription) async throws {
        if let existing = try record(id: subscription.id) {
            existing.update(from: subscription)
        } else {
            modelContext.insert(SubscriptionRecord(subscription))
        }
        try modelContext.save()
        announce()
    }

    public func delete(id: UUID) async throws {
        guard let existing = try record(id: id) else { return }
        modelContext.delete(existing)
        try modelContext.save()
        announce()
    }

    /// §10's delete-everything leaves nothing derived from a statement behind, rates included.
    public func deleteAll() async throws {
        try modelContext.delete(model: SubscriptionRecord.self)
        try modelContext.delete(model: ObservedRateRecord.self)
        try modelContext.delete(model: OfficialRateRecord.self)
        try modelContext.save()
        announce()
    }

    /// Re-importing an overlapping statement must refresh a subscription, never duplicate it.
    public func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] {
        var claimed: Set<UUID> = []
        for (key, candidates) in Dictionary(
            grouping: detected.map({ Subscription(confirming: $0) }), by: \.matchKey)
        {
            let stored = try records(matching: key)
            for candidate in candidates {
                guard
                    let existing = pair(
                        candidate, from: stored, isOnlyOneOfItsKind: candidates.count == 1,
                        claimed: &claimed)
                else {
                    modelContext.insert(SubscriptionRecord(candidate))
                    continue
                }
                existing.update(from: merging(candidate, into: existing.subscription))
            }
        }
        try modelContext.save()
        announce()
        return try await all()
    }

    /// One merchant can bill several subscriptions at once (§7.1), so merchant, currency and
    /// cadence cannot say which stored row a charge belongs to — amount decides, and a row is
    /// claimed only once per import. A lone incoming charge meeting a lone stored one merges
    /// whatever the amount, because that is a price change and not a second subscription.
    private func pair(
        _ candidate: Subscription, from stored: [SubscriptionRecord], isOnlyOneOfItsKind: Bool,
        claimed: inout Set<UUID>
    ) -> SubscriptionRecord? {
        let free = stored.filter { !claimed.contains($0.id) }
        let match =
            free.first { AmountTolerance.matches($0.amount, candidate.amount) }
            ?? (isOnlyOneOfItsKind && free.count == 1 ? free.first : nil)
        if let match { claimed.insert(match.id) }
        return match
    }

    /// Keeps the stored identity and the widest known history; an older statement never rewinds
    /// the current amount or next charge. The name is the stored one whatever the statement says,
    /// because it may be the one the user typed.
    private func merging(_ incoming: Subscription, into stored: Subscription) -> Subscription {
        let newest = incoming.lastChargeDate >= stored.lastChargeDate ? incoming : stored
        return Subscription(
            id: stored.id,
            merchant: stored.merchant,
            amount: newest.amount,
            isVariableAmount: newest.isVariableAmount,
            currency: newest.currency,
            cadence: newest.cadence,
            firstChargeDate: min(stored.firstChargeDate, incoming.firstChargeDate),
            lastChargeDate: max(stored.lastChargeDate, incoming.lastChargeDate),
            nextChargeDate: newest.nextChargeDate,
            charges: merged(stored.charges, incoming.charges),
            priceChanges: newest.priceChanges.isEmpty ? stored.priceChanges : newest.priceChanges,
            isActive: stored.isActive,
            confidence: newest.confidence
        )
    }

    private func record(id: UUID) throws -> SubscriptionRecord? {
        try modelContext.fetch(
            FetchDescriptor<SubscriptionRecord>(predicate: #Predicate { $0.id == id })
        ).first
    }

    /// Overlapping statements repeat charges; the same money on the same day is the same charge.
    private func merged(_ stored: [Charge], _ incoming: [Charge]) -> [Charge] {
        var known = Set(stored.map(Self.identity))
        var all = stored
        for charge in incoming where known.insert(Self.identity(charge)).inserted {
            all.append(charge)
        }
        return all.sorted { $0.date < $1.date }
    }

    private static func identity(_ charge: Charge) -> String {
        "\(charge.date.timeIntervalSince1970)|\(charge.amount)|\(charge.currency)"
    }

    private func records(matching key: String) throws -> [SubscriptionRecord] {
        try modelContext.fetch(
            FetchDescriptor<SubscriptionRecord>(predicate: #Predicate { $0.matchKey == key })
        )
    }
}
