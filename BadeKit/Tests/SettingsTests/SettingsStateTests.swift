import Core
import Foundation
import Localization
import Testing

@testable import Settings

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private func subscription(
    _ merchant: String, currency: String = "GEL", amount: String = "10.00", active: Bool = true
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency,
        cadence: .monthly, firstChargeDate: day("2026-01-05"), lastChargeDate: day("2026-07-05"),
        nextChargeDate: day("2026-08-05"), isActive: active, confidence: .confident)
}

/// One observation is enough for either direction: a rate book inverts what it holds, and picks
/// the nearest observation to the date asked for however far away it is.
private func rates(_ from: String, _ to: String, _ rate: String) -> RateBook {
    var book = RateBook()
    book.record(
        ObservedRate(date: day("2026-01-05"), from: from, to: to, rate: Decimal(string: rate)!))
    return book
}

private func state(_ subscriptions: [Subscription] = [], rates: RateBook = RateBook())
    -> SettingsState
{
    var state = SettingsState(currency: "GEL", language: .english)
    _ = state.apply(.loaded(subscriptions, rates))
    return state
}

@Suite("Settings")
struct SettingsStateTests {
    @Test func changingTheCurrencyTellsTheAppThatOwnsIt() {
        var subject = state()

        #expect(subject.apply(.currencyChanged("USD")) == .report(.currencyChanged("USD")))
        #expect(subject.currency == "USD")
    }

    /// A picker hands back what is already selected every time it closes.
    @Test func choosingWhatIsAlreadyChosenChangesNothing() {
        var subject = state()

        #expect(subject.apply(.currencyChanged("GEL")) == nil)
        #expect(subject.apply(.languageChanged(.english)) == nil)
    }

    @Test func changingTheLanguageTellsTheAppThatOwnsIt() {
        var subject = state()

        #expect(subject.apply(.languageChanged(.georgian)) == .report(.languageChanged(.georgian)))
        #expect(subject.language == .georgian)
    }

    /// The picker used to list every ISO currency, and picking almost any of them totalled to
    /// zero — a rate book holds observed pairs and bridges nothing.
    @Test func onlyCurrenciesEverySubscriptionConvertsIntoAreOffered() {
        let subject = state(
            [
                subscription("Netflix", currency: "USD"), subscription("Spotify"),
                subscription("ChatGPT", currency: "USD"),
            ], rates: rates("USD", "GEL", "2.6716"))

        #expect(subject.displayCurrencies == ["GEL", "USD"])
        #expect(subject.canChooseCurrency)
    }

    /// Being charged in a currency is not the same as being able to be shown a total in it. A
    /// multi-currency account pays a dollar charge from a dollar balance and records no rate.
    @Test func aCurrencyChargedInWithNoRateToItIsNotOffered() {
        let subject = state([
            subscription("Netflix", currency: "USD"), subscription("Spotify"),
        ])

        #expect(subject.displayCurrencies == ["GEL"])
        #expect(subject.canChooseCurrency == false)
    }

    /// The common case in Georgia. A screen with one ticked row on it is not a choice.
    @Test func oneCurrencyIsNoChoiceAtAll() {
        let subject = state([subscription("Spotify"), subscription("MAGTICOM")])

        #expect(subject.displayCurrencies == ["GEL"])
        #expect(subject.canChooseCurrency == false)
    }

    /// Otherwise a display currency that stopped converting would hide the only row that could
    /// change it, and there would be no way back.
    @Test func whateverIsSelectedStaysOfferedEvenIfItNoLongerConverts() {
        var subject = state(
            [subscription("Netflix", currency: "USD"), subscription("Spotify")],
            rates: rates("USD", "GEL", "2.6716"))

        _ = subject.apply(.currencyChanged("USD"))
        _ = subject.apply(.loaded([subscription("Netflix", currency: "EUR")], RateBook()))

        #expect(subject.displayCurrencies.contains("USD"))
        #expect(subject.canChooseCurrency)
    }

    @Test func thereIsNothingToExportUntilSomethingIsStored() {
        #expect(state().hasData == false)
        #expect(state([subscription("Netflix")]).hasData)
    }

    @Test func clearingEverythingAsksFirstAndThenReportsIt() {
        var subject = state([subscription("Netflix")])

        #expect(subject.apply(.deleteAllRequested) == nil)
        #expect(subject.isConfirmingDeleteAll)
        #expect(subject.apply(.deleteAllConfirmed) == .deleteEverything)
        #expect(subject.isConfirmingDeleteAll == false)
        #expect(subject.apply(.storeCleared) == .report(.dataCleared))
    }

    /// The screen keeps what it was showing rather than emptying itself. The root is already on
    /// its way to Welcome, and blanking the data section first made it vanish out from under the
    /// reader a moment before the screen it belonged to did.
    @Test func clearingLeavesTheScreenAsItWasUntilTheRootMovesOn() {
        var subject = state([subscription("Netflix")])

        _ = subject.apply(.storeCleared)

        #expect(subject.hasData)
    }

    @Test func backingOutOfTheConfirmationDeletesNothing() {
        var subject = state([subscription("Netflix")])
        _ = subject.apply(.deleteAllRequested)

        #expect(subject.apply(.confirmationDismissed) == nil)
        #expect(subject.isConfirmingDeleteAll == false)
        #expect(subject.hasData)
    }

    @Test func appearingReadsTheStore() {
        var subject = SettingsState(currency: "GEL", language: .english)

        #expect(subject.apply(.appeared) == .load)
    }

    @Test func anEntitlementThatArrivesReachesTheRoot() {
        var subject = state()

        #expect(subject.apply(.proChecked(true)) == .report(.proChanged(true)))
        #expect(subject.isPro)
    }

    /// The refund case. This screen re-reads the entitlement every time it appears, and it used to
    /// keep a `false` to itself — which left the root's cache saying Pro, so Upcoming, the FX card
    /// and the widget all stayed unlocked until the next launch.
    @Test func anEntitlementThatIsRevokedAlsoReachesTheRoot() {
        var subject = SettingsState(currency: "GEL", language: .english, isPro: true)

        #expect(subject.apply(.proChecked(false)) == .report(.proChanged(false)))
        #expect(subject.isPro == false)
    }

    /// Settings re-reads on every appearance and on every return to the foreground, so the
    /// unchanged answer is the common case and must stay silent.
    @Test func rereadingTheSameEntitlementReportsNothing() {
        var entitled = SettingsState(currency: "GEL", language: .english, isPro: true)
        var unentitled = state()

        #expect(entitled.apply(.proChecked(true)) == nil)
        #expect(unentitled.apply(.proChecked(false)) == nil)
    }
}

@Suite("Exported data")
struct SubscriptionExportTests {
    @Test func csvCarriesAHeaderAndARowPerSubscription() {
        let text = SubscriptionCSV.text(for: [
            subscription("Netflix", currency: "USD", amount: "12.99"),
            subscription("Spotify", amount: "15.20", active: false),
        ])
        let lines = text.split(separator: "\n")

        #expect(lines.count == 3)
        #expect(lines[0].hasPrefix("merchant,amount,currency,cadence"))
        #expect(lines[1] == "Netflix,12.99,USD,monthly,2026-08-05,2026-01-05,2026-07-05,0,active")
        #expect(lines[2].hasSuffix(",cancelled"))
    }

    /// A merchant name is free text and can hold the separator it is being written next to.
    @Test func acommaInAMerchantNameDoesNotBreakTheColumns() {
        let text = SubscriptionCSV.text(for: [subscription("Apple, Inc.")])

        #expect(text.contains("\"Apple, Inc.\","))
        #expect(text.split(separator: "\n")[1].split(separator: ",").count == 10)
    }

    @Test func choosingAReminderLeadTellsTheAppThatSchedulesThem() {
        var subject = state()

        #expect(
            subject.apply(.reminderLeadChanged(.twoDays))
                == .report(.reminderLeadChanged(.twoDays)))
        #expect(subject.reminder.lead == .twoDays)
    }

    @Test func choosingTheSameLeadReschedulesNothing() {
        var subject = state()
        _ = subject.apply(.reminderLeadChanged(.oneDay))

        #expect(subject.apply(.reminderLeadChanged(.oneDay)) == nil)
    }

    @Test func choosingATimeKeepsItAsMinutesAfterMidnight() {
        var subject = state()

        #expect(
            subject.apply(.reminderTimeChanged(21 * 60 + 30))
                == .report(.reminderTimeChanged(21 * 60 + 30)))
        #expect(subject.reminder.hour == 21)
        #expect(subject.reminder.minute == 30)
    }

    /// Read back every time the screen returns, because iOS Settings can revoke it in between.
    @Test func aBlockedPermissionIsRecordedWithoutTellingTheAppAnything() {
        var subject = state()

        #expect(subject.apply(.reminderAuthorizationChecked(true)) == nil)
        #expect(subject.isReminderDenied)
    }

    @Test func aquoteInAMerchantNameIsDoubled() {
        let text = SubscriptionCSV.text(for: [subscription("The \"Gym\"")])

        #expect(text.contains("\"The \"\"Gym\"\"\""))
    }

    @Test func csvOfNothingIsStillAValidFile() {
        let text = SubscriptionCSV.text(for: [])

        #expect(text.split(separator: "\n").count == 1)
    }

    @Test func jsonRoundTripsBackIntoSubscriptions() throws {
        let subscriptions = [subscription("Netflix", currency: "USD", amount: "12.99")]

        let data = try SubscriptionJSON.data(for: subscriptions)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(try decoder.decode([Subscription].self, from: data) == subscriptions)
    }

    @Test func moneySurvivesTheExportExactly() {
        let text = SubscriptionCSV.text(for: [subscription("Netflix", amount: "1234.5678")])

        #expect(text.contains(",1234.5678,"))
    }
}
