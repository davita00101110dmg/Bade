import Core
import Foundation

/// One card purchase. TBC prints merchant, amount, currency and the moment of purchase as a single
/// intact run, which is the only part of the row worth reading: extraction lands the bank's own
/// columns in separate blocks, so the account-currency amount follows barely a quarter of records.
struct TBCCardRecord {
    // Regex is not Sendable, so these are computed rather than shared constants.
    private static var chargePattern:
        Regex<(Substring, Substring, Substring, Substring, Substring, Substring, Substring)>
    {
        /^\s*\S*\s*-\s+(.{2,80}?),\s*([0-9,]+\.[0-9]{2})\s+([A-Z]{3}),\s*([A-Za-z]{3})\s+([0-9]{1,2})\s+([0-9]{4})\s+[0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)/
    }
    private static var mccPattern: Regex<(Substring, Substring)> {
        /MCC:\s*([0-9]{2,4})/
    }

    /// A record's own fields are over well before this; beyond it lie the next row's.
    private static let bodyLimit = 220
    private static let sourceLineLimit = 240

    let transaction: RawTransaction

    /// `body` runs from just after the terminal marker to the start of the next one. The marker
    /// also appears inside descriptions, so a body that does not open with a charge is not a record.
    init?(body: Substring) {
        let head = body.prefix(Self.bodyLimit)
        guard let charge = try? Self.chargePattern.firstMatch(in: head),
            let amount = Decimal(string: charge.2.replacingOccurrences(of: ",", with: "")),
            let date = StatementDate.from(day: charge.5, monthName: charge.4, year: charge.6),
            let mcc = try? Self.mccPattern.firstMatch(in: head)
        else { return nil }

        transaction = RawTransaction(
            date: date,
            rawDescription: charge.1.trimmingCharacters(in: .whitespaces),
            amount: amount,
            currency: String(charge.3),
            sourceLine: body.prefix(Self.sourceLineLimit).trimmingCharacters(in: .whitespaces),
            mcc: String(mcc.1)
        )
    }
}
