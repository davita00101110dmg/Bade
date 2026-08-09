import Core
import Foundation
import SwiftData

@ModelActor
public actor SubscriptionStore: SubscriptionRepository {
    /// Local store only — no CloudKit, no remote container (§10).
    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: SubscriptionRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
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
    }

    public func delete(id: UUID) async throws {
        guard let existing = try record(id: id) else { return }
        modelContext.delete(existing)
        try modelContext.save()
    }

    public func deleteAll() async throws {
        try modelContext.delete(model: SubscriptionRecord.self)
        try modelContext.save()
    }

    /// Re-importing an overlapping statement must refresh a subscription, never duplicate it.
    public func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] {
        for candidate in detected.map({ Subscription(confirming: $0) }) {
            if let existing = try record(matching: candidate.matchKey) {
                existing.update(from: merging(candidate, into: existing.subscription))
            } else {
                modelContext.insert(SubscriptionRecord(candidate))
            }
        }
        try modelContext.save()
        return try await all()
    }

    /// Keeps the stored identity and the widest known history; an older statement never rewinds
    /// the current amount or next charge.
    private func merging(_ incoming: Subscription, into stored: Subscription) -> Subscription {
        let newest = incoming.lastChargeDate >= stored.lastChargeDate ? incoming : stored
        return Subscription(
            id: stored.id,
            merchant: newest.merchant,
            amount: newest.amount,
            isVariableAmount: newest.isVariableAmount,
            currency: newest.currency,
            cadence: newest.cadence,
            firstChargeDate: min(stored.firstChargeDate, incoming.firstChargeDate),
            lastChargeDate: max(stored.lastChargeDate, incoming.lastChargeDate),
            nextChargeDate: newest.nextChargeDate,
            occurrenceCount: max(stored.occurrenceCount, incoming.occurrenceCount),
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

    private func record(matching key: String) throws -> SubscriptionRecord? {
        try modelContext.fetch(
            FetchDescriptor<SubscriptionRecord>(predicate: #Predicate { $0.matchKey == key })
        ).first
    }
}
