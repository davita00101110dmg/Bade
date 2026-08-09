import Core
import Foundation

/// Overlapping statement imports repeat lines; §7's (date, amount, rawDescription) plus currency,
/// which the spec omits but without which two currencies at one amount collapse into one charge.
struct TransactionDeduplicator {
    func deduplicate(_ transactions: [NormalizedTransaction]) -> [NormalizedTransaction] {
        var seen: Set<Key> = []
        return transactions.filter { seen.insert(Key($0.raw)).inserted }
    }

    private struct Key: Hashable {
        let date: Date
        let amount: Decimal
        let currency: String
        let rawDescription: String

        init(_ raw: RawTransaction) {
            date = raw.date
            amount = raw.amount
            currency = raw.currency
            rawDescription = raw.rawDescription
        }
    }
}
