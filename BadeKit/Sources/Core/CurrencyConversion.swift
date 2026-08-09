import Foundation

/// What the bank did to a foreign charge. The gap between the scheme's rate and the bank's own
/// rate is the markup §8 reports.
public struct CurrencyConversion: Equatable, Sendable, Codable {
    public let from: String
    public let to: String
    /// The rate the bank actually charged.
    public let bankRate: Decimal
    /// The card scheme's reference rate, when the statement prints it.
    public let schemeRate: Decimal?

    public init(from: String, to: String, bankRate: Decimal, schemeRate: Decimal? = nil) {
        self.from = from
        self.to = to
        self.bankRate = bankRate
        self.schemeRate = schemeRate
    }

    public var markupFraction: Decimal? {
        guard let schemeRate, schemeRate > 0 else { return nil }
        return (bankRate - schemeRate) / schemeRate
    }
}

/// Rates observed in a statement, so totals can span currencies using what the bank really
/// charged rather than a published rate. §10's FX module replaces this with dated NBG rates.
public struct RateBook: Equatable, Sendable, Codable {
    private var rates: [String: Decimal] = [:]

    public init() {}

    public mutating func record(_ conversion: CurrencyConversion) {
        rates[Self.key(conversion.from, conversion.to)] = conversion.bankRate
    }

    public func rate(from: String, to: String) -> Decimal? {
        if from == to { return 1 }
        if let direct = rates[Self.key(from, to)] { return direct }
        if let inverse = rates[Self.key(to, from)], inverse > 0 { return 1 / inverse }
        return nil
    }

    public func convert(_ amount: Decimal, from: String, to: String) -> Decimal? {
        rate(from: from, to: to).map { amount * $0 }
    }

    private static func key(_ from: String, _ to: String) -> String { "\(from)|\(to)" }
}
