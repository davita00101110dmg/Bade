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

private func state(_ subscriptions: [Subscription] = []) -> SettingsState {
    var state = SettingsState(currency: "GEL", language: .english)
    _ = state.apply(.loaded(subscriptions))
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

    @Test func currenciesAlreadyChargedComeFirstWithoutRepeats() {
        let subject = state([
            subscription("Netflix", currency: "USD"), subscription("Spotify"),
            subscription("ChatGPT", currency: "USD"),
        ])

        #expect(subject.knownCurrencies == ["GEL", "USD"])
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
        #expect(subject.hasData == false)
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
