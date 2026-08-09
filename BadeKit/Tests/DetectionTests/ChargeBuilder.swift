import Core
import Foundation

func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

func charge(
    _ merchant: String,
    _ iso: String,
    _ amount: String,
    currency: String = "GEL",
    rawDescription: String? = nil
) -> NormalizedTransaction {
    let description = rawDescription ?? "SP \(merchant.uppercased()) REF001"
    return NormalizedTransaction(
        raw: RawTransaction(
            date: day(iso),
            rawDescription: description,
            amount: Decimal(string: amount)!,
            currency: currency,
            sourceLine: "\(iso) \(description) \(amount) \(currency)"
        ),
        merchant: merchant,
        merchantConfidence: 1
    )
}

/// `count` charges on the same day-of-month, starting at `iso`.
func monthlyCharges(
    _ merchant: String, from iso: String, count: Int, amount: String, currency: String = "GEL"
) -> [NormalizedTransaction] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]

    return (0..<count).map { offset in
        let date = calendar.date(byAdding: .month, value: offset, to: day(iso))!
        return charge(merchant, formatter.string(from: date), amount, currency: currency)
    }
}
