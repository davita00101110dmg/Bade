import Foundation

extension Calendar {
    /// The calendar every date in Bade is reasoned about in.
    ///
    /// A statement date carries no meaningful local time, and the arithmetic must not change with
    /// the time zone the phone happens to be in — a charge on the 1st has to stay on the 1st on a
    /// flight. Three modules each built this for themselves, with the same force unwrap in each.
    public static let bade: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        // The only time zone guaranteed to exist on every platform.
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()
}
