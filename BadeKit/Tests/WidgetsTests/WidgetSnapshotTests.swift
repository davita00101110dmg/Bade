import Core
import Foundation
import Testing

@testable import Widgets

/// The widget never computes anything: whatever is wrong here is wrong on someone's home screen
/// until the app next runs, so this is the one place the arithmetic can be caught.
@Suite("Widget snapshot")
struct WidgetSnapshotTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    private func subscription(
        _ merchant: String, _ amount: String, _ currency: String = "GEL",
        _ cadence: Cadence = .monthly, next: Date, charged: [Date] = [], isActive: Bool = true
    ) -> Subscription {
        let money = Decimal(string: amount) ?? 0
        return Subscription(
            merchant: merchant, amount: money, currency: currency,
            cadence: cadence, firstChargeDate: next, lastChargeDate: next, nextChargeDate: next,
            charges: charged.map {
                Charge(date: $0, amount: money, currency: currency, conversion: nil)
            },
            isActive: isActive, confidence: .confident)
    }

    private func snapshot(
        _ subscriptions: [Subscription], currency: String = "GEL", rates: RateBook = RateBook(),
        isPro: Bool = true
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            subscriptions: subscriptions, currency: currency, rates: rates, isPro: isPro,
            from: date(2026, 8, 12), calendar: calendar)
    }

    /// This calendar month, not a levelled one: charges due after today plus whatever the month
    /// already saw.
    @Test func theTotalIsThisMonthsCharges() {
        let subject = snapshot([
            subscription("Netflix", "39", next: date(2026, 8, 20)),
            subscription("Spotify", "24.90", next: date(2026, 8, 25)),
        ])

        #expect(subject.monthTotal == Decimal(string: "63.90"))
        #expect(subject.remaining == Decimal(string: "63.90"))
        #expect(subject.currency == "GEL")
    }

    /// The bar is only honest if the two halves add up to the whole. What the month already saw
    /// comes from recorded charges — nothing is ever projected backwards.
    @Test func whatIsLeftIsPartOfTheMonthsTotal() {
        let subject = snapshot([
            subscription(
                "Already", "40", next: date(2026, 9, 5), charged: [date(2026, 8, 5)]),
            subscription("Coming", "60", next: date(2026, 8, 20)),
        ])

        #expect(subject.monthTotal == 100)
        #expect(subject.remaining == 60)
        #expect(subject.spentFraction == 0.4)
    }

    /// Nothing left to charge reads as done, not as an empty bar.
    @Test func aMonthAlreadyPaidIsFull() {
        let subject = snapshot([subscription("Netflix", "39", next: date(2026, 8, 30))])

        #expect(WidgetSnapshot.empty.spentFraction == 1)
        #expect(subject.spentFraction == 0)
    }

    @Test func aCancelledSubscriptionIsNotCharged() {
        let subject = snapshot([
            subscription("Netflix", "39", next: date(2026, 8, 20)),
            subscription("Gone", "10", next: date(2026, 8, 15), isActive: false),
        ])

        #expect(subject.monthTotal == 39)
        #expect(subject.upcoming.map(\.merchant) == ["Netflix"])
    }

    /// A monthly charge falls inside the horizon twice. Two rows saying "Netflix" would waste the
    /// only three a widget has.
    @Test func eachSubscriptionTakesOneRowAtMost() {
        let subject = snapshot([subscription("Netflix", "39", next: date(2026, 8, 20))])

        #expect(subject.upcoming.map(\.merchant) == ["Netflix"])
        #expect(subject.upcoming.first?.date == date(2026, 8, 20))
    }

    /// A medium widget has room for three rows, and the soonest are the ones worth the space.
    @Test func onlyTheSoonestFewAreCarried() {
        let subject = snapshot([
            subscription("Fourth", "10", next: date(2026, 8, 28)),
            subscription("First", "10", next: date(2026, 8, 13)),
            subscription("Third", "10", next: date(2026, 8, 22)),
            subscription("Second", "10", next: date(2026, 8, 18)),
        ])

        #expect(subject.upcoming.count == WidgetSnapshot.upcomingLimit)
        #expect(subject.upcoming.map(\.merchant) == ["First", "Second", "Third"])
    }

    @Test func chargesAreConvertedIntoTheDisplayCurrency() throws {
        var rates = RateBook()
        rates.record(
            ObservedRate(date: date(2026, 8, 1), from: "USD", to: "GEL", rate: Decimal(string: "2.7") ?? 0))

        let subject = snapshot(
            [subscription("Netflix", "10", "USD", next: date(2026, 8, 20))], rates: rates)
        let charge = try #require(subject.upcoming.first)

        #expect(charge.currency == "GEL")
        #expect(charge.amount == 27)
    }

    /// Unconvertible keeps its own currency rather than being dropped or silently mislabelled —
    /// the same choice the calendar and the list make.
    @Test func whatCannotBeConvertedKeepsItsOwnCurrency() throws {
        let subject = snapshot([subscription("Netflix", "12.99", "USD", next: date(2026, 8, 20))])
        let charge = try #require(subject.upcoming.first)

        #expect(charge.currency == "USD")
        #expect(charge.amount == Decimal(string: "12.99"))
    }

    @Test func nothingStoredIsAnEmptyWidgetRatherThanAZero() {
        #expect(!snapshot([]).hasData)
        #expect(!WidgetSnapshot.empty.hasData)
        #expect(snapshot([subscription("Netflix", "39", next: date(2026, 8, 20))]).hasData)
    }

    /// A separate process cannot see the app's language override, so it travels in the snapshot —
    /// otherwise a phone in English shows an English widget to someone reading Bade in Georgian.
    @Test func theAppsLanguageTravelsWithTheSnapshot() {
        let georgian = WidgetSnapshot(
            subscriptions: [], currency: "GEL", rates: RateBook(), isPro: true,
            localeIdentifier: "ka", from: date(2026, 8, 12), calendar: calendar)

        #expect(georgian.locale.identifier == "ka")
    }

    @Test func nolanguageFollowsTheDevice() {
        #expect(WidgetSnapshot.empty.locale == .autoupdatingCurrent)
    }

    @Test func aSnapshotSurvivesBeingWrittenAndReadBack() throws {
        let folder = URL(filePath: NSTemporaryDirectory())
            .appending(path: "bade-widget-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let feed = WidgetFeed(directory: folder)
        let subject = WidgetSnapshot(
            subscriptions: [subscription("Netflix", "39", next: date(2026, 8, 20))],
            currency: "GEL", rates: RateBook(), isPro: true, localeIdentifier: "ka",
            from: date(2026, 8, 12), calendar: calendar)

        feed.publish(subject)

        #expect(feed.read() == subject)
    }

    /// Before the app has ever published, and in any test process without a group container.
    @Test func areadWithNothingThereIsEmptyRatherThanACrash() {
        let missing = URL(filePath: NSTemporaryDirectory()).appending(path: UUID().uuidString)

        #expect(WidgetFeed(directory: missing).read() == .empty)
    }
}
