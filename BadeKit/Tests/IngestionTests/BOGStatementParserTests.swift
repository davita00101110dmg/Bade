import Core
import Foundation
import Testing

@testable import Ingestion

private let parser = BOGStatementParser()

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

@Suite("BOG parser")
struct BOGStatementParserTests {
    @Test func parsesACardPayment() throws {
        let statement = """
            09/05/2026 Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, \
            United States of America; MCC:4899; Date: 27/05/2026 00:00; Card No: ****0000;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].amount == Decimal(string: "10.29")!)
        #expect(transactions[0].currency == "GEL")
        #expect(transactions[0].date == day("2026-05-27"))
        #expect(transactions[0].rawDescription == "GOOGLE *YouTubePremium, United States of America")
    }

    /// Extraction wraps fields mid-value; line breaks must not end a field.
    @Test func parsesRecordsWrappedAcrossLines() throws {
        let statement = """
            09/05/2026 Payment - Amount: GEL8.99; Merchant: Epidemic
            Sound, Sweden; MCC:5815; Date: 21/06/2026
            00:00; Card No: ****0000;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].rawDescription == "Epidemic Sound, Sweden")
        #expect(transactions[0].date == day("2026-06-21"))
    }

    /// Two records routinely land on one extracted line.
    @Test func splitsRecordsMergedOntoOneLine() throws {
        let statement = """
            Income - Amount GEL1.75; Placing funds on Deposit N CD00000000 Payment - Amount: \
            GEL14.99; Merchant: SETANTA.COM, United Kingdom; MCC:4899; Date: 10/06/2026 00:00; \
            Card No: ****0000; Payment - Amount: GEL19.99; Merchant: AMZ*Adobe, United States \
            of America; MCC:5734; Date: 19/06/2026 00:00;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 2)
        #expect(transactions.map(\.rawDescription) == ["SETANTA.COM, United Kingdom", "AMZ*Adobe, United States of America"])
        #expect(transactions[1].amount == Decimal(string: "19.99")!)
    }

    @Test func parsesThousandsSeparator() throws {
        let statement = "Payment - Amount: GEL1,000.00; Merchant: TBC_P2P, Georgia; MCC:6538; Date: 04/08/2026 10:13;"

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].amount == Decimal(string: "1000.00")!)
    }

    /// Merchant addresses contain semicolons, so the field ends at the MCC label, not the first ';'.
    @Test func keepsSemicolonsInsideMerchantAddresses() throws {
        let statement = """
            Payment - Amount: GEL500.00; Merchant: www.example.ge, Tbilisi, vakis r; some street 12v; \
            b.3a; MCC:5947; Date: 22/07/2026 09:00;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].rawDescription == "www.example.ge, Tbilisi, vakis r; some street 12v; b.3a")
    }

    @Test func parsesGeorgianStatements() throws {
        let statement = """
            28/05/2026 გადახდა - თანხა: GEL10.29; ობიექტი: GOOGLE *YouTubePremium, \
            United States of America; MCC:4899; თარიღი: 27/05/2026 00:00;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].date == day("2026-05-27"))
        #expect(transactions[0].rawDescription == "GOOGLE *YouTubePremium, United States of America")
    }

    /// Page footers are injected mid-record by extraction.
    @Test func survivesPageFootersInsideRecords() throws {
        let statement = """
            გადახდა - თანხა: GEL8.99; ობიექტი: Epidemic Sound, Sweden; MCC:5815; \
            გვ. 13 (სულ 54 გვ.) GEL -0.75 თარიღი: 21/06/2026 00:00;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].date == day("2026-06-21"))
    }

    @Test func ignoresNonPurchaseRecords() throws {
        let statement = """
            09/05/2026 Payment - Amount GEL2.00; Funds transfer from electronic till to the deposit, \
            Agreement number# GE00BG0000000000000000 09/05/2026 Outgoing Transfer - Amount: GEL50.00; \
            Beneficiary: person01 person02; Account: GE00BG0000000000000000; Bank: JSC Bank of Georgia \
            Payment - Amount: GEL11.99; Merchant: APPLE.COM/BILL, Ireland; MCC:5815; Date: 18/06/2026 00:00;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].rawDescription == "APPLE.COM/BILL, Ireland")
    }

    @Test func rejectsUnrecognisedFormats() {
        #expect(throws: StatementParsingError.unrecognisedFormat) {
            try parser.parse("Some other bank's statement, entirely different layout.")
        }
        #expect(!parser.canParse("Some other bank's statement."))
    }

    @Test func reportsWhenNothingParsed() {
        #expect(throws: StatementParsingError.suspiciouslyFewTransactions(found: 0)) {
            try parser.parse("Merchant: nothing parseable here, no payment records at all")
        }
    }

    @Test func identifiesItself() {
        #expect(BOGStatementParser.identifier == "bog-pdf-v1")
        #expect(BOGStatementParser.displayName == "Bank of Georgia")
    }
}
