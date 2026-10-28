import Foundation

/// ±8% (spec §7.1) — wide enough to absorb FX drift on foreign-currency subscriptions.
public enum AmountTolerance {
    public static let fraction = Decimal(string: "0.08")!

    public static func matches(_ lhs: Decimal, _ rhs: Decimal) -> Bool {
        guard lhs != 0, rhs != 0 else { return lhs == rhs }
        return abs(lhs - rhs) / max(lhs, rhs) <= fraction
    }
}
