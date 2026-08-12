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
        try SubscriptionJSON.data(for: try await all())
    }
}

/// Kept apart from the repository so a screen holding subscriptions already can render them
/// without reading the store again — a share sheet needs its payload before it opens.
public enum SubscriptionJSON {
    public static func data(for subscriptions: [Subscription]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(subscriptions)
    }
}

/// The other half of §10's export: a summary a spreadsheet can open. Lossy by design — charge
/// history and price changes do not fit a row — so JSON remains the one that round-trips.
public enum SubscriptionCSV {
    public static func text(for subscriptions: [Subscription]) -> String {
        let rows = subscriptions.map { subscription in
            [
                subscription.merchant,
                "\(subscription.amount)",
                subscription.currency,
                subscription.cadence.rawValue,
                iso(subscription.nextChargeDate),
                iso(subscription.firstChargeDate),
                iso(subscription.lastChargeDate),
                "\(subscription.occurrenceCount)",
                subscription.isActive ? "active" : "cancelled",
            ].map(escaped).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static let header = [
        "merchant", "amount", "currency", "cadence", "next_charge", "first_charge", "last_charge",
        "charges", "status",
    ].joined(separator: ",")

    /// A merchant name can hold a comma or a quote; RFC 4180 says double the quotes and wrap.
    private static func escaped(_ value: String) -> String {
        guard value.contains(where: { ",\"\n".contains($0) }) else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
