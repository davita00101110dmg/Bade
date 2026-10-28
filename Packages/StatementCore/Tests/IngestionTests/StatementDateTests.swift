import Foundation
import Testing

@testable import StatementCore

@Suite("Statement dates")
struct StatementDateTests {
    /// A malformed row must be dropped, not moved: 31/02 used to land on 3 March and 15/13 in the
    /// following January, which also stretched the statement's end and ended live subscriptions.
    @Test(arguments: [
        ("31", "02", "2026"), ("29", "02", "2026"), ("31", "04", "2026"), ("00", "05", "2026"),
        ("15", "13", "2026"), ("15", "00", "2026"),
    ])
    func rejectsADayTheCalendarDoesNotHave(day: String, month: String, year: String) {
        #expect(StatementDate.from(day: day, month: month, year: year) == nil)
    }

    @Test func acceptsTheLeapDay() {
        #expect(StatementDate.from(day: "29", month: "02", year: "2028") != nil)
    }

    @Test func rejectsADayTheCalendarDoesNotHaveWhenTheMonthIsNamed() {
        #expect(StatementDate.from(day: "30", monthName: "Feb", year: "2026") == nil)
        #expect(StatementDate.from(day: "28", monthName: "Feb", year: "2026") != nil)
    }
}
