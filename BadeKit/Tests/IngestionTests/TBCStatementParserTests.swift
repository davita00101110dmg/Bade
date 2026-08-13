import Core
import Foundation
import Testing

@testable import Ingestion

private let parser = TBCStatementParser()

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: iso)!
}

/// A row as extraction delivers it: the posting date, the card block the bank prints intact, then
/// its own columns. Only the card block is a record; everything after it is the row's furniture.
private func row(
    posted: String = "03/06/2025",
    location: String = "GEO",
    merchant: String,
    amount: String,
    currency: String = "GEL",
    purchased: String = "Jun 1 2025 03:12PM",
    mcc: String = "5815"
) -> String {
    """
    \(posted) POS \(location) - \(merchant), \(amount) \(currency), \(purchased), \
    ქუთაისი, საქართველო, MCC: \(mcc), VI, 400000******0000 გადახდა ბარათით, \
    TBCBGE22, GE00TB0000000000000000 \(amount) 1234.56
    """
}

@Suite("TBC parser")
struct TBCStatementParserTests {
    @Test func parsesACardPayment() throws {
        let transactions = try parser.parse(row(merchant: "SPOTIFY", amount: "15.20"))

        #expect(transactions.count == 1)
        #expect(transactions[0].rawDescription == "SPOTIFY")
        #expect(transactions[0].amount == Decimal(string: "15.20")!)
        #expect(transactions[0].currency == "GEL")
        #expect(transactions[0].mcc == "5815")
    }

    /// The terminal's location shares the column with the merchant and is blank for e-commerce.
    /// It takes one value across a whole statement, so it identifies nothing and is dropped.
    @Test(arguments: ["GEO", ""])
    func dropsTheTerminalLocationColumn(location: String) throws {
        let transactions = try parser.parse(
            row(location: location, merchant: "APPLE.COM/BILL", amount: "11.99"))

        #expect(transactions.count == 1)
        #expect(transactions[0].rawDescription == "APPLE.COM/BILL")
    }

    @Test func keepsADashInsideAMerchantName() throws {
        let transactions = try parser.parse(row(merchant: "AMAZON - PRIME", amount: "9.99"))

        #expect(transactions[0].rawDescription == "AMAZON - PRIME")
    }

    /// The moment of purchase is inside the record; the date in front of it is when TBC posted it,
    /// which for a card charge is a day or three later.
    @Test func readsThePurchaseDateNotThePostingDate() throws {
        let transactions = try parser.parse(
            row(posted: "03/06/2025", merchant: "SETANTA.COM", amount: "14.99",
                purchased: "Jun 1 2025 03:12PM"))

        #expect(transactions[0].date == day("2025-06-01"))
    }

    @Test(arguments: [
        ("Jan", "01"), ("Feb", "02"), ("Mar", "03"), ("Apr", "04"), ("May", "05"), ("Jun", "06"),
        ("Jul", "07"), ("Aug", "08"), ("Sep", "09"), ("Oct", "10"), ("Nov", "11"), ("Dec", "12"),
    ])
    func readsEveryMonthAbbreviation(name: String, number: String) throws {
        let transactions = try parser.parse(
            row(merchant: "NETFLIX", amount: "35.99", purchased: "\(name) 9 2025 11:05AM"))

        #expect(transactions[0].date == day("2025-\(number)-09"))
    }

    /// Extraction wraps a row mid-field; line breaks must not end one.
    @Test func parsesRecordsWrappedAcrossLines() throws {
        let statement = """
            03/06/2025 POS GEO - Epidemic
            Sound, 8.99 GEL, Jun 1 2025
            03:12PM, ქუთაისი, MCC: 5815, VI, 400000******0000, TBCBGE22, GE00TB0000000000000000
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.count == 1)
        #expect(transactions[0].rawDescription == "Epidemic Sound")
        #expect(transactions[0].date == day("2025-06-01"))
    }

    @Test func splitsRecordsMergedOntoOneLine() throws {
        let statement = [
            row(merchant: "SPOTIFY", amount: "15.20"),
            row(posted: "05/06/2025", merchant: "GOOGLE *YouTubePremium", amount: "10.29",
                purchased: "Jun 4 2025 08:00AM", mcc: "4899"),
        ].joined(separator: " ")

        let transactions = try parser.parse(statement)
        #expect(transactions.map(\.rawDescription) == ["SPOTIFY", "GOOGLE *YouTubePremium"])
        #expect(transactions[1].amount == Decimal(string: "10.29")!)
        #expect(transactions[1].mcc == "4899")
    }

    /// A charge settled from a balance already in its own currency is recorded in that currency;
    /// the statement prints no second amount, so none is invented.
    @Test func recordsTheCurrencyTheChargeWasMadeIn() throws {
        let transactions = try parser.parse(
            row(merchant: "OPENAI", amount: "20.00", currency: "USD"))

        #expect(transactions[0].currency == "USD")
        #expect(transactions[0].amount == Decimal(string: "20.00")!)
        #expect(transactions[0].conversion == nil)
    }

    @Test func parsesThousandsSeparator() throws {
        let transactions = try parser.parse(row(merchant: "AIRBNB", amount: "1,240.00"))

        #expect(transactions[0].amount == Decimal(string: "1240.00")!)
    }

    /// The terminal marker also appears inside Georgian descriptions — on the fee charged for a
    /// card operation, most of all. Those rows carry no card block and are not purchases.
    @Test func ignoresTheMarkerInsideDescriptions() {
        let statement = """
            03/06/2025 POS ოპერაციის საკომისიო, TBCBGE22, GE00TB0000000000000000 0.35 1234.56
            """

        #expect(throws: StatementParsingError.suspiciouslyFewTransactions(found: 0)) {
            try parser.parse(statement)
        }
    }

    @Test func ignoresRowsThatAreNotCardPurchases() throws {
        let statement = """
            01/06/2025 გადარიცხვა ანგარიშებს შორის, TBCBGE22, GE00TB0000000000000000 500.00 1734.56 \
            \(row(merchant: "SETANTA.COM", amount: "14.99")) \
            04/06/2025 ჩარიცხვა ხელფასი, TBCBGE22, GE00TB0000000000000000 2000.00 3734.56
            """

        let transactions = try parser.parse(statement)
        #expect(transactions.map(\.rawDescription) == ["SETANTA.COM"])
    }

    @Test func readsConversionRates() throws {
        let statement = """
            12/07/2025 კონვერტაცია (ყიდვა-გაყიდვა: 1 USD = 2.7100 GEL) ანგარიშებს შორის, \
            TBCBGE22, GE00TB0000000000000000 100.00 500.00
            """

        let rates = parser.exchangeRates(in: statement)
        #expect(rates.count == 1)
        #expect(rates[0] == ObservedRate(
            date: day("2025-07-12"), from: "USD", to: "GEL", rate: Decimal(string: "2.71")!))
    }

    /// A rate quoted per hundred is a hundredth of the rate, or the markup is overstated a hundredfold.
    @Test func dividesRatesByTheQuantityQuoted() throws {
        let statement = """
            12/07/2025 კონვერტაცია (კურსი: 100 AMD = 0.7100 GEL), TBCBGE22, GE00TB0000000000000000
            """

        let rates = parser.exchangeRates(in: statement)
        #expect(rates.count == 1)
        #expect(rates[0].rate == Decimal(string: "0.0071")!)
    }

    @Test func findsNoRatesWhenTheStatementPrintsNone() throws {
        #expect(parser.exchangeRates(in: row(merchant: "SPOTIFY", amount: "15.20")).isEmpty)
    }

    @Test func rejectsUnrecognisedFormats() {
        #expect(throws: StatementParsingError.unrecognisedFormat) {
            try parser.parse("Some other bank's statement, entirely different layout.")
        }
        #expect(!parser.canParse("Some other bank's statement."))
    }

    /// Both banks are Georgian and both appear in each other's transfer records, so the two
    /// signatures have to be exclusive rather than merely present.
    @Test func theTwoFormatsDoNotClaimEachOther() {
        let tbc = row(merchant: "SPOTIFY", amount: "15.20")
        let bog = """
            09/05/2026 Payment - Amount: GEL10.29; Merchant: GOOGLE *YouTubePremium, \
            United States of America; MCC:4899; Date: 27/05/2026 00:00;
            """

        #expect(parser.canParse(tbc))
        #expect(!parser.canParse(bog))
        #expect(BOGStatementParser().canParse(bog))
        #expect(!BOGStatementParser().canParse(tbc))
    }

    @Test func reportsWhenNothingParsed() {
        #expect(throws: StatementParsingError.suspiciouslyFewTransactions(found: 0)) {
            try parser.parse("TBCBGE22 GE00TB0000000000000000 nothing parseable here")
        }
    }

    @Test func identifiesItself() {
        #expect(TBCStatementParser.identifier == "tbc-pdf-v1")
        #expect(TBCStatementParser.displayName == "TBC Bank")
    }
}
