import Foundation

/// A statement prints calendar days, not instants: a charge belongs to the day beside it whatever
/// time zone the phone is in, so every parser reads dates against the same fixed calendar.
enum StatementDate {
    private static let utc = Calendar.bade

    static func from(
        day: some StringProtocol, month: some StringProtocol, year: some StringProtocol
    ) -> Date? {
        guard let day = Int(day), let month = Int(month), let year = Int(year) else { return nil }
        return utc.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// TBC prints the moment of purchase with an English month abbreviation rather than a number.
    static func from(
        day: some StringProtocol, monthName: some StringProtocol, year: some StringProtocol
    ) -> Date? {
        guard let month = months[monthName.prefix(3).lowercased()] else { return nil }
        return from(day: day, month: String(month), year: year)
    }

    private static let months = [
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
    ]
}
