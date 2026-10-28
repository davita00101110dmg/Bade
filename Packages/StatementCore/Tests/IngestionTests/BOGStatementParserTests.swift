import Foundation
import Testing

@testable import StatementCore

private let parser = BOGStatementParser()

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

@Suite("BOG parser")
struct BOGStatementParserTests {
    /// The statement states the markup outright: the scheme's rate and the bank's own, side by
    /// side. A Georgian export prints both under Georgian labels, and reading it for English ones
    /// left every charge with no conversion — so the markup card had nothing to show at all.
    @Test(arguments: [
        """
        09/05/2026 Payment - Amount: GEL14.00; Merchant: AMAZON MKTPL, \
        United States of America; MCC:4899; Date: 27/05/2026 00:00; Card No: ****0000; \
        Payment transaction amount and currency: 14.00 GEL; \
        Card scheme conversion rate (USD-GEL): 2.7237; Bank conversion rate (USD-GEL): 2.7558
        """,
        """
        09/05/2026 გადახდა - თანხა: GEL14.00; ობიექტი: AMAZON MKTPL, \
        United States of America; MCC:4899; თარიღი: 27/05/2026 00:00; ბარათის No: ****0000; \
        გადახდის ოპერაციის თანხა და ვალუტა: 14.00 GEL; \
        საბარათე სქემის კონვერტაციის კურსი (USD-GEL): 2.7237; \
        ბანკის კონვერტაციის კურსი (USD-GEL): 2.7558
        """,
    ])
    func readsTheStatedMarkupInEitherLanguage(statement: String) throws {
        let conversion = try #require(try parser.parse(statement).first?.conversion)

        #expect(conversion.from == "USD")
        #expect(conversion.to == "GEL")
        #expect(conversion.bankRate == Decimal(string: "2.7558")!)
        #expect(conversion.schemeRate == Decimal(string: "2.7237")!)
        let markup = try #require(conversion.markupFraction)
        #expect(markup > Decimal(string: "0.011")! && markup < Decimal(string: "0.012")!)
    }

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

    /// A refund prints the same conversion lines a purchase does; they are the refund's alone.
    @Test func readsAPurchaseOnlyUpToTheNextRecord() throws {
        let statement = """
            09/04/2026 Payment - Amount: GEL35.99; Merchant: NETFLIX.COM, Netherlands; MCC:4899; \
            Date: 09/04/2026 00:00; Card No: ****0000; 12/04/2026 Refund - Amount: GEL35.99; \
            Merchant: NETFLIX.COM, Netherlands; MCC:4899; Date: 12/04/2026 00:00; Card No: ****0000; \
            Card scheme conversion rate (USD-GEL): 2.6500; Bank conversion rate (USD-GEL): 2.6900
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions.first?.conversion == nil)
    }

    /// An exchange opens like a purchase but names no merchant; the next record must not lend one.
    @Test func aRecordWithNoMerchantDoesNotBorrowTheNextOne() throws {
        let statement = """
            02/03/2026 Payment - Amount GEL540.00; Foreign Exchange. FX Rate:2.7. Counter-amount: \
            USD200.00. konvertatsia 03/03/2026 Refund - Amount: GEL19.99; Merchant: AMZ*Adobe, \
            United States of America; MCC:5734; Date: 01/03/2026 00:00; Card No: ****0000; \
            09/03/2026 Payment - Amount: GEL35.99; Merchant: NETFLIX.COM, Netherlands; MCC:4899; \
            Date: 09/03/2026 00:00; Card No: ****0000;
            """

        #expect(try parser.parse(statement).map(\.rawDescription) == ["NETFLIX.COM, Netherlands"])
    }

    /// An unreadable amount drops the record; a price inside the merchant's name is not its amount.
    @Test func readsTheAmountOnlyRightAfterTheLabel() {
        let statement = """
            06/07/2026 Payment - Amount: GEL; Merchant: SAMPLE TOPUP 10.00, Tbilisi; MCC:4814; \
            Date: 06/07/2026 10:00; Card No: ****0000;
            """

        #expect(throws: StatementParsingError.suspiciouslyFewTransactions(found: 0)) {
            try parser.parse(statement)
        }
    }

    /// A date in the wrong shape drops the record rather than taking the next one's posting date.
    @Test func readsTheDateOnlyRightAfterTheLabel() throws {
        let statement = """
            09/01/2026 Payment - Amount: GEL8.00; Merchant: DEMO KIOSK, Tbilisi; MCC:5994; \
            Date: 2026-01-09 08:15; Card No: ****0000; 10/01/2026 Payment - Amount: GEL7.50; \
            Merchant: SAMPLE BAKERY, Tbilisi; MCC:5462; Date: 10/01/2026 07:40; Card No: ****0000;
            """

        #expect(try parser.parse(statement).map(\.rawDescription) == ["SAMPLE BAKERY, Tbilisi"])
    }

    /// A card check debits nothing; it is not a purchase, and a transaction is always positive.
    @Test func ignoresAZeroAmountCardCheck() throws {
        let statement = """
            08/02/2026 Payment - Amount: GEL0.00; Merchant: APPLE.COM/BILL, Ireland; MCC:5818; \
            Date: 08/02/2026 00:00; Card No: ****0000; 09/02/2026 Payment - Amount: GEL2.99; \
            Merchant: APPLE.COM/BILL, Ireland; MCC:5818; Date: 09/02/2026 00:00; Card No: ****0000;
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.map(\.amount) == [Decimal(string: "2.99")!])
    }

    @Test func identifiesItself() {
        #expect(BOGStatementParser.identifier == "bog-pdf-v1")
        #expect(BOGStatementParser.displayName == "Bank of Georgia")
    }
}
