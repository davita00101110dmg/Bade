import Core
import Foundation

/// Produced vs expected, as a multiset: order is not part of the contract, duplicates are.
public struct GoldenComparison: Equatable, Sendable {
    public let missing: [DetectedSubscription]
    public let unexpected: [DetectedSubscription]

    public var matches: Bool { missing.isEmpty && unexpected.isEmpty }

    public var failureMessage: String? {
        guard !matches else { return nil }
        var lines: [String] = []
        if !missing.isEmpty {
            lines.append("missing \(missing.count) expected subscription(s):")
            lines += missing.map { "  - \(summary($0))" }
        }
        if !unexpected.isEmpty {
            lines.append("produced \(unexpected.count) unexpected subscription(s):")
            lines += unexpected.map { "  + \(summary($0))" }
        }
        return lines.joined(separator: "\n")
    }
}

public func compareGolden(
    actual: [DetectedSubscription],
    expected: [DetectedSubscription]
) -> GoldenComparison {
    var remaining = actual
    var missing: [DetectedSubscription] = []

    for subscription in expected {
        if let index = remaining.firstIndex(of: subscription) {
            remaining.remove(at: index)
        } else {
            missing.append(subscription)
        }
    }

    return GoldenComparison(missing: sorted(missing), unexpected: sorted(remaining))
}

private func sorted(_ subscriptions: [DetectedSubscription]) -> [DetectedSubscription] {
    subscriptions.sorted {
        ($0.merchant, $0.amount.description) < ($1.merchant, $1.amount.description)
    }
}

/// One line per subscription — full struct dumps drown real diffs.
private func summary(_ subscription: DetectedSubscription) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    let next = formatter.string(from: subscription.nextChargeDate)
    return """
        \(subscription.merchant) \(subscription.amount) \(subscription.currency) \
        \(subscription.cadence.rawValue) ×\(subscription.occurrences.count) \
        next \(next) (\(subscription.confidence.rawValue))
        """
}
