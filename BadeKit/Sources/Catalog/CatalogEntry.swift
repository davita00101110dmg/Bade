import Core
import Foundation

/// A published price for a service, in the currency it is actually billed in.
public struct PricePoint: Equatable, Sendable {
    public let amount: Decimal
    public let currency: String
    public let cadence: Cadence

    public init(amount: Decimal, currency: String, cadence: Cadence) {
        self.amount = amount
        self.currency = currency
        self.cadence = cadence
    }

    public static func monthly(_ amount: String, _ currency: String = "USD") -> PricePoint {
        PricePoint(amount: decimal(amount), currency: currency, cadence: .monthly)
    }

    public static func annual(_ amount: String, _ currency: String = "USD") -> PricePoint {
        PricePoint(amount: decimal(amount), currency: currency, cadence: .annual)
    }
}

/// String literals, never float literals — `15.49 as Decimal` would round-trip through Double.
private func decimal(_ literal: String) -> Decimal {
    guard let value = Decimal(string: literal) else {
        preconditionFailure("malformed catalog price literal: \(literal)")
    }
    return value
}

public struct CatalogEntry: Equatable, Sendable {
    public let merchant: String
    /// Billing rhythm the service is normally sold on, used when no price point matches.
    public let typicalCadence: Cadence
    public let aliases: [String]
    public let pricePoints: [PricePoint]

    public init(
        _ merchant: String,
        _ typicalCadence: Cadence,
        aliases: [String] = [],
        pricePoints: [PricePoint] = []
    ) {
        self.merchant = merchant
        self.typicalCadence = typicalCadence
        self.aliases = aliases
        self.pricePoints = pricePoints
    }

    var matchTokens: [String] { ([merchant] + aliases).map(MerchantName.folded) }
}

/// Case, spacing and punctuation vary wildly across statements; compare on letters and digits only.
enum MerchantName {
    static func folded(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
