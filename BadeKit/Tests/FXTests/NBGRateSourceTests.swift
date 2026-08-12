import Core
import Foundation
import Testing

@testable import FX

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

/// Trimmed from a real response, kept verbatim in shape: a quantity of 1 and a quantity of 10,
/// because the second is the one that goes wrong quietly.
private let payload = """
    [{"date":"2026-08-07T00:00:00.000Z","currencies":[
      {"code":"USD","quantity":1,"rateFormated":"2.6223","diffFormated":"0.0006",
       "rate":2.6223,"name":"US Dollar","diff":-0.0006,
       "validFromDate":"2026-08-07T00:00:00.000Z"},
      {"code":"AED","quantity":10,"rateFormated":"7.1394","diffFormated":"0.0016",
       "rate":7.1394,"name":"United Arab Emirates Dirhams","diff":-0.0016,
       "validFromDate":"2026-08-07T00:00:00.000Z"}
    ]}]
    """

@Suite("Reading NBG's rates")
struct NBGRateSourceTests {
    private func published() throws -> [PublishedRate] {
        try JSONDecoder().decode([PublishedDay].self, from: Data(payload.utf8))
            .flatMap(\.currencies)
    }

    @Test func areallResponseDecodes() throws {
        #expect(try published().map(\.code) == ["USD", "AED"])
    }

    @Test func aratequotedPerUnitIsTakenAsItIs() throws {
        let usd = try #require(try published().first { $0.code == "USD" })

        #expect(usd.perUnitRate == Decimal(string: "2.6223"))
    }

    /// The quiet one: AED is published per ten, and using 7.1394 as the rate would overstate a
    /// markup tenfold.
    @Test func aratequotedPerTenIsDividedDown() throws {
        let aed = try #require(try published().first { $0.code == "AED" })

        #expect(aed.perUnitRate == Decimal(string: "0.71394"))
    }

    @Test(arguments: [
        #"{"code":"USD","quantity":0,"rateFormated":"2.62"}"#,
        #"{"code":"USD","quantity":1,"rateFormated":"—"}"#,
        #"{"code":"USD","quantity":1,"rateFormated":"0"}"#,
    ])
    func anonsenseRateIsRefusedRatherThanUsed(_ json: String) throws {
        let rate = try JSONDecoder().decode(PublishedRate.self, from: Data(json.utf8))

        #expect(rate.perUnitRate == nil)
    }

    @Test func theurlAsksForOneDayAndNamesNoCurrency() throws {
        let url = try #require(NBGRateSource.url(for: day("2026-08-07"), in: utc))

        #expect(url.absoluteString.hasSuffix("json?date=2026-08-07"))
        #expect(url.absoluteString.contains("currencies=") == false, "the wire never names one")
    }

    @Test func asingleDigitMonthAndDayArePadded() throws {
        let url = try #require(NBGRateSource.url(for: day("2026-01-05"), in: utc))

        #expect(url.absoluteString.hasSuffix("date=2026-01-05"))
    }

    /// Nothing here may reach the network on its own, and nothing may fail the caller.
    @Test func askingForNothingAsksNobody() async {
        let source = NBGRateSource(calendar: utc)

        #expect(await source.rates(for: [], on: [day("2026-08-07")]).isEmpty)
        #expect(await source.rates(for: ["USD"], on: []).isEmpty)
    }
}
