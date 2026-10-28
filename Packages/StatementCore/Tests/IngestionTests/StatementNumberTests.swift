import Foundation
import Testing

@testable import StatementCore

@Suite("Statement numbers")
struct StatementNumberTests {
    @Test(arguments: [
        ("14.99", "14.99"), ("14,99", "14.99"), ("1,240.50", "1240.50"), ("1.240,50", "1240.50"),
        ("12,450.75", "12450.75"), ("1,000", "1000"), ("67", "67"), ("100,00", "100.00"),
        ("2.700,00", "2700.00"), ("15,518.09", "15518.09"),
    ])
    func readsAnAmountInEitherConvention(text: String, expected: String) {
        #expect(StatementNumber.amount(text) == Decimal(string: expected)!)
    }

    @Test(arguments: [("2.6859", "2.6859"), ("2,6859", "2.6859"), ("2,7", "2.7"), ("0.0071", "0.0071")])
    func readsARateWhicheverSeparatorItUses(text: String, expected: String) {
        #expect(StatementNumber.rate(text) == Decimal(string: expected)!)
    }
}
