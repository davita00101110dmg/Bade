import Core
import Foundation

/// Stands in for Ingestion + Normalization + Detection; identity `resolveMerchant` misses the fixture.
enum StubPipeline {
    static func run(
        _ statement: Data,
        resolveMerchant: (String) -> String = { $0 }
    ) -> [DetectedSubscription] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var order: [String] = []
        var groups: [String: [RawTransaction]] = [:]

        let lines = String(decoding: statement, as: UTF8.self)
            .split(separator: "\n")
            .dropFirst()  // header

        for line in lines {
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            let description = fields[1]
            let transaction = RawTransaction(
                date: formatter.date(from: fields[0])!,
                rawDescription: description,
                amount: Decimal(string: fields[2])!,
                currency: fields[3],
                sourceLine: String(line)
            )
            if groups[description] == nil { order.append(description) }
            groups[description, default: []].append(transaction)
        }

        return order.map { description in
            let occurrences = groups[description]!
            return DetectedSubscription(
                merchant: resolveMerchant(description),
                amount: occurrences[0].amount,
                currency: occurrences[0].currency,
                cadence: .monthly,
                occurrences: occurrences,
                nextChargeDate: calendar.date(
                    byAdding: .month, value: 1, to: occurrences.last!.date)!,
                confidence: .confident,
                priceChanges: []
            )
        }
    }
}
