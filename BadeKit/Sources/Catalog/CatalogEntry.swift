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
    /// The merchant also sells one-off purchases, so a charge at an unpublished price proves
    /// nothing. Apple bills iCloud and a film rental down the same line; Netflix only sells Netflix.
    public let sellsOneOffs: Bool

    public init(
        _ merchant: String,
        _ typicalCadence: Cadence,
        aliases: [String] = [],
        pricePoints: [PricePoint] = [],
        sellsOneOffs: Bool = false
    ) {
        self.merchant = merchant
        self.typicalCadence = typicalCadence
        self.aliases = aliases
        self.pricePoints = pricePoints
        self.sellsOneOffs = sellsOneOffs
    }

    var matchTokens: [String] { ([merchant] + aliases).map(MerchantName.folded) }
}

/// Case, spacing and punctuation vary wildly across statements; compare on letters and digits only.
enum MerchantName {
    static func folded(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Descriptors glue the brand to whatever else the processor felt like sending, and the joins
    /// are punctuation as often as spaces: "CLAUDE.AI SUBSCRIPTION", "ANTHROPIC* CLAUDE SUB".
    static func words(_ value: String) -> [String] {
        value.split { !$0.isLetter && !$0.isNumber }
            .map { folded(String($0)) }
            .filter { !$0.isEmpty }
    }
}
