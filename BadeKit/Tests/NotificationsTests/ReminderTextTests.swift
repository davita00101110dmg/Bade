import Core
import Foundation
import Testing

@testable import Notifications

@Suite("Reminder wording")
struct ReminderTextTests {
    private let english = ReminderText(locale: Locale(identifier: "en_US"))
    private let georgian = ReminderText(locale: Locale(identifier: "ka_GE"))

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    /// A Thursday, so the weekday wording has something recognisable to render.
    private var chargeDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 20)) ?? .distantPast
    }

    private func charge(_ merchant: String, _ amount: String, _ currency: String = "GEL")
        -> UpcomingCharge
    {
        let subscription = Subscription(
            merchant: merchant, amount: Decimal(string: amount) ?? 0, currency: currency,
            cadence: .monthly, firstChargeDate: chargeDate, lastChargeDate: chargeDate,
            nextChargeDate: chargeDate, confidence: .confident)
        return UpcomingCharge(
            subscription: subscription, date: chargeDate, amount: subscription.amount,
            currency: currency)
    }

    private func reminder(_ charges: [UpcomingCharge], daysAhead: Int) -> ChargeReminder {
        ChargeReminder(
            chargeDate: chargeDate, fireDate: chargeDate, daysAhead: daysAhead, charges: charges)
    }

    /// The title carries only the timing; the merchant and the price belong in the body, where
    /// there is room for them.
    @Test func theTitleSaysWhenAndTheBodySaysWhatAndHowMuch() {
        let one = reminder([charge("Netflix", "39")], daysAhead: 1)

        #expect(english.titleResource(for: one) == .reminder.tomorrow)
        #expect(english.body(for: one).contains("Netflix"))
        #expect(english.body(for: one).contains("39"))
        #expect(english.body(for: one).contains("₾"))
    }

    @Test func aChargeTodaySaysToday() {
        let one = reminder([charge("Netflix", "39")], daysAhead: 0)

        #expect(english.titleResource(for: one) == .reminder.today)
    }

    /// Two or three days out, "in 2 days" is arithmetic the reader has to do. A weekday is not.
    @Test func furtherAheadNamesTheWeekday() {
        let far = reminder([charge("Netflix", "39")], daysAhead: 3)

        #expect(english.titleResource(for: far) == .reminder.onDay("Thursday"))
    }

    @Test func severalChargesAreListedAndTotalled() {
        let many = reminder(
            [charge("Netflix", "39"), charge("Spotify", "24.90"), charge("MAGTICOM", "35")],
            daysAhead: 1)

        #expect(english.titleResource(for: many) == .reminder.tomorrow)
        #expect(english.body(for: many).contains("and MAGTICOM"))
        #expect(english.body(for: many).contains("98.90"))
    }

    /// No rate is available at scheduling time, and inventing one to sum two currencies would be
    /// exactly the arithmetic Bade refuses to guess at.
    @Test func mixedCurrenciesShowMerchantsWithoutATotal() {
        let mixed = reminder(
            [charge("Netflix", "12.99", "USD"), charge("MAGTICOM", "35", "GEL")], daysAhead: 1)
        let body = english.body(for: mixed)

        #expect(body.contains("Netflix"))
        #expect(body.contains("MAGTICOM"))
        #expect(!body.contains("12.99"))
        #expect(!body.contains("47.99"))
    }

    /// The app's language, not the phone's: someone reading Bade in Georgian on an English phone
    /// gets a Georgian weekday in the reminder.
    @Test func theAppsOwnLanguageNamesTheDay() {
        let far = reminder([charge("Netflix", "39")], daysAhead: 3)

        #expect(georgian.titleResource(for: far) != english.titleResource(for: far))
    }
}
