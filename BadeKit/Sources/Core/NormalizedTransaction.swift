import Foundation

public struct NormalizedTransaction: Equatable, Sendable, Codable {
    public let raw: RawTransaction
    public let merchant: String
    /// 0...1
    public let merchantConfidence: Double

    public init(raw: RawTransaction, merchant: String, merchantConfidence: Double) {
        self.raw = raw
        self.merchant = merchant
        self.merchantConfidence = merchantConfidence
    }
}
