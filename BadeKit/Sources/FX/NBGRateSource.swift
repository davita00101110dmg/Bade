import Core
import Foundation

/// The National Bank of Georgia's published daily rates — the one network call Bade makes
/// (constraint 2), and the baseline the bank's own rate is judged against.
///
/// The request carries no account data, and deliberately does not name a currency: asking for a
/// day returns all forty-odd of them, so what is on the wire is "someone wants a day's rates"
/// rather than "someone holds a USD subscription".
public struct NBGRateSource: OfficialRateSource {
    private let session: URLSession
    private let calendar: Calendar

    public init(session: URLSession = .shared, calendar: Calendar = .current) {
        self.session = session
        self.calendar = calendar
    }

    /// NBG publishes one day per request, so days are fetched together rather than in sequence.
    /// A day that fails is simply absent — nothing here can fail the caller.
    public func rates(for currencies: Set<String>, on dates: Set<Date>) async -> [OfficialRate] {
        guard !currencies.isEmpty, !dates.isEmpty else { return [] }

        return await withTaskGroup(of: [OfficialRate].self) { group in
            for date in dates.prefix(Self.dayLimit) {
                group.addTask { await rates(on: date, wanted: currencies) }
            }
            var all: [OfficialRate] = []
            for await day in group { all += day }
            return all
        }
    }

    /// A statement is months long, and a screen only ever needs a handful of days; the cap is
    /// there so a pathological input cannot turn into a hundred requests.
    private static let dayLimit = 24

    private func rates(on date: Date, wanted: Set<String>) async -> [OfficialRate] {
        guard let url = Self.url(for: date, in: calendar) else { return [] }
        guard let (data, response) = try? await session.data(from: url),
            (response as? HTTPURLResponse)?.statusCode == 200,
            let days = try? JSONDecoder().decode([PublishedDay].self, from: data)
        else { return [] }

        let day = calendar.startOfDay(for: date)
        return days.flatMap(\.currencies)
            .filter { wanted.contains($0.code) }
            .compactMap { published in
                published.perUnitRate.map {
                    OfficialRate(date: day, currency: published.code, rate: $0)
                }
            }
    }

    static func url(for date: Date, in calendar: Calendar) -> URL? {
        var components = URLComponents(
            string: "https://nbg.gov.ge/gw/api/ct/monetarypolicy/currencies/en/json")
        components?.queryItems = [URLQueryItem(name: "date", value: Self.day(date, in: calendar))]
        return components?.url
    }

    /// The API keys off a plain calendar day, so the date is written out rather than formatted by
    /// a locale that might render it in another calendar entirely.
    private static func day(_ date: Date, in calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

/// One day's publication, exactly as NBG sends it.
struct PublishedDay: Decodable {
    let currencies: [PublishedRate]
}

struct PublishedRate: Decodable {
    let code: String
    /// How many units the rate is quoted for. Most are 1; some — AED, JPY — are 10 or 100, and
    /// taking the rate at face value would overstate a markup by that factor.
    let quantity: Int
    /// Sent as a JSON number, so it is read from the string form to keep it exact.
    let rateFormated: String

    var perUnitRate: Decimal? {
        guard quantity > 0, let quoted = Decimal(string: rateFormated), quoted > 0 else {
            return nil
        }
        return quoted / Decimal(quantity)
    }
}
