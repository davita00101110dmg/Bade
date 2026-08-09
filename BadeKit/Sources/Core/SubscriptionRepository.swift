import Foundation

/// Feature modules depend on this, never on `Persistence`; `App` supplies the implementation.
public protocol SubscriptionRepository: Sendable {
    func all() async throws -> [Subscription]
    func save(_ subscription: Subscription) async throws
    /// Re-importing an overlapping statement must refresh a subscription, never duplicate it.
    @discardableResult
    func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription]
    func delete(id: UUID) async throws
    /// §10 requires a full delete in v1.
    func deleteAll() async throws
}

extension SubscriptionRepository {
    /// §10 requires data export in v1; `Subscription` is Codable, so this needs no store support.
    public func exportJSON() async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(try await all())
    }
}
