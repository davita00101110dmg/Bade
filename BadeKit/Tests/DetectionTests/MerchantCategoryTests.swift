import Core
import Foundation
import Testing

@testable import Detection

@Suite("Merchant categories")
struct MerchantCategoryTests {
    private func charge(mcc: String?) -> RawTransaction {
        RawTransaction(
            date: day("2026-01-05"), rawDescription: "X", amount: 10, currency: "GEL",
            sourceLine: "x", mcc: mcc)
    }

    @Test(arguments: ["5814", "5812", "4215", "5411", "5541", "5993"])
    func excludesCategoriesThatNeverRecur(mcc: String) {
        #expect(!MerchantCategory.canRecur(charge(mcc: mcc)))
    }

    @Test(arguments: ["4816", "4899", "5734", "5815", "5818", "4814", "5968", "7997", "4900"])
    func keepsSubscriptionCapableCategories(mcc: String) {
        #expect(MerchantCategory.canRecur(charge(mcc: mcc)))
    }

    /// Statements without a category must still be detectable — the blocklist fails open.
    @Test func keepsTransactionsWithNoCategory() {
        #expect(MerchantCategory.canRecur(charge(mcc: nil)))
    }

    @Test func fastFoodOnAPerfectMonthlyRhythmIsNotASubscription() {
        let lunches = ["2026-01-05", "2026-02-05", "2026-03-05"].map { date in
            NormalizedTransaction(
                raw: RawTransaction(
                    date: day(date), rawDescription: "McDonald's", amount: Decimal(string: "22.70")!,
                    currency: "GEL", sourceLine: "x", mcc: "5814"),
                merchant: "McDonald's", merchantConfidence: 1)
        }
        #expect(SubscriptionDetector().detect(lunches).isEmpty)
    }
}
