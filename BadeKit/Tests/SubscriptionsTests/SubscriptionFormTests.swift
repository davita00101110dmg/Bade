import Core
import Foundation
import Testing

@testable import Subscriptions

private func day(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")!
    return formatter.date(from: iso)!
}

private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

private func blank(currency: String = "GEL", knownCurrencies: [String] = [])
    -> SubscriptionFormState
{
    SubscriptionFormState(
        editing: nil, currency: currency, knownCurrencies: knownCurrencies,
        today: day("2026-08-10"), calendar: calendar)
}

private func stored(
    merchant: String = "Netflix", amount: String = "35.99", currency: String = "GEL",
    cadence: Cadence = .monthly, charges: [Charge] = [], active: Bool = true
) -> Subscription {
    Subscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency, cadence: cadence,
        firstChargeDate: day("2026-05-20"), lastChargeDate: day("2026-07-20"),
        nextChargeDate: day("2026-08-20"), charges: charges, isActive: active,
        confidence: .confident)
}

private func filled(_ subscription: Subscription) -> SubscriptionFormState {
    SubscriptionFormState(
        editing: subscription, currency: "GEL", today: day("2026-08-10"), calendar: calendar)
}

private func typed(
    _ state: inout SubscriptionFormState, merchant: String = "Netflix", amount: String = "35.99"
) {
    _ = state.apply(.merchantChanged(merchant))
    _ = state.apply(.amountChanged(amount))
}

@Suite("Subscription form")
struct SubscriptionFormTests {
    /// A decimal pad held down used to produce an amount of any length at all, which then had to be
    /// totalled, laid out in a row, drawn on a widget and read aloud.
    @Test func thewholePartStopsGrowingAtSixDigits() {
        var subject = blank()

        _ = subject.apply(.amountChanged("999999999999"))

        #expect(subject.draft.amount == "999999")
    }

    /// The tetri are always reachable, whatever the lari have used up. A flat character count made
    /// them compete: at six characters "999999" left no room for a separator, let alone two digits.
    @Test func thedecimalsAreAlwaysReachableRegardlessOfTheWholePart() {
        #expect(DecimalInput.limited("999999.99") == "999999.99")
        #expect(DecimalInput.limited("999999.999") == "999999.99", "a third has nowhere to show")
        #expect(DecimalInput.limited("1234567.89") == "123456.89")
    }

    /// A Georgian keyboard offers a comma for the number an English one writes with a full stop, so
    /// whichever was typed survives; `parse` is what reconciles them.
    @Test func whicheverSeparatorWasTypedIsKept() {
        #expect(DecimalInput.limited("14,99") == "14,99")
        #expect(DecimalInput.parse("14,99") == Decimal(string: "14.99"))
    }

    /// Unreachable from a decimal pad, but a paste is not a keyboard.
    @Test func asecondSeparatorAndAnyLetterAreDropped() {
        #expect(DecimalInput.limited("1.2.3") == "1.23")
        #expect(DecimalInput.limited("12abc34") == "1234")
    }

    /// Half-typed states have to survive, or the separator could never be reached at all.
    @Test func atrailingSeparatorIsLeftAloneWhileItIsBeingTyped() {
        #expect(DecimalInput.limited("14.") == "14.")
        #expect(DecimalInput.parse("14.") == Decimal(string: "14"))
    }

    /// Truncated rather than refused, and the difference is not academic. Refusing leaves the state
    /// unchanged, and SwiftUI does not push an unchanged value back into a `TextField` — so typing
    /// carried on unbounded and the limit only appeared to bite when the field lost focus. Returning
    /// a shorter string is what makes it apply on the keystroke.
    @Test func theLimitAppliesOnEveryKeystrokeRatherThanOnLosingFocus() {
        var subject = blank()

        for character in "1234567.891" {
            _ = subject.apply(.amountChanged(subject.draft.amount + String(character)))
        }

        #expect(subject.draft.amount == "123456.89")
    }

    /// A name reaches a notification title and a widget, neither of which truncates as kindly as
    /// a list row does.
    @Test func aServiceNameStopsGrowingAtTheLimit() {
        var subject = blank()

        _ = subject.apply(.merchantChanged(String(repeating: "a", count: 500)))

        #expect(subject.draft.merchant.count == MerchantInput.characterLimit)
    }

    /// This field is the edit path as well as the entry one, so the limit must sit above every name
    /// the app can produce on its own — otherwise editing a detected subscription would silently
    /// rename it. The longest in the bundled catalog is 26.
    @Test func nonameTheAppItselfProducesIsTruncated() {
        let longest = "Tesla Premium Connectivity"
        var subject = blank()

        _ = subject.apply(.merchantChanged(longest))

        #expect(subject.draft.merchant == longest)
    }

    @Test func arealSubscriptionAmountFitsInside() {
        #expect(DecimalInput.limited("14.99") == "14.99")
        #expect(DecimalInput.limited("999.99") == "999.99")
        #expect(DecimalInput.limited("1200.00") == "1200.00")
    }

    @Test func aBlankFormCannotBeSaved() {
        #expect(blank().canSave == false)
        #expect(blank().isNew)
        #expect(blank().hasChanges == false)
    }

    @Test func aNameWithoutAPriceCannotBeSaved() {
        var subject = blank()
        _ = subject.apply(.merchantChanged("Netflix"))

        #expect(subject.canSave == false)
        #expect(subject.apply(.saveTapped) == nil)
    }

    @Test func aPriceWithoutANameCannotBeSaved() {
        var subject = blank()
        _ = subject.apply(.amountChanged("35.99"))

        #expect(subject.canSave == false)
    }

    @Test func whitespaceIsNotAName() {
        var subject = blank()
        typed(&subject, merchant: "   ")

        #expect(subject.canSave == false)
    }

    @Test func zeroIsNotAPrice() {
        var subject = blank()
        typed(&subject, amount: "0")

        #expect(subject.canSave == false)
    }

    @Test func aNameAndAPriceIsEnough() {
        var subject = blank()
        typed(&subject)

        #expect(subject.canSave)
        let saved = try? #require(subject.result)
        #expect(saved?.merchant == "Netflix")
        #expect(saved?.amount == Decimal(string: "35.99")!)
        #expect(saved?.currency == "GEL")
        #expect(saved?.confidence == .confident)
    }

    @Test func theNameIsTrimmedBeforeItIsSaved() {
        var subject = blank()
        typed(&subject, merchant: "  Netflix  ")

        #expect(subject.result?.merchant == "Netflix")
    }

    /// A decimal pad shows a comma on a Georgian phone and a full stop on an English one.
    @Test(arguments: ["35.99", "35,99"])
    func eitherDecimalSeparatorIsReadTheSame(_ text: String) {
        var subject = blank()
        typed(&subject, amount: text)

        #expect(subject.result?.amount == Decimal(string: "35.99")!)
    }

    @Test func aNewSubscriptionHasNoHistoryBehindIt() {
        var subject = blank()
        typed(&subject)

        #expect(subject.result?.charges.isEmpty == true)
        #expect(subject.result?.priceChanges.isEmpty == true)
    }

    /// Not a charge anyone claims happened — it is the date the FX lookup converts at.
    @Test func theDatesOfAHistorylessSubscriptionFollowItsRhythm() {
        var subject = blank()
        typed(&subject)
        _ = subject.apply(.cadenceChanged(.annual))

        let saved = try? #require(subject.result)
        #expect(saved?.nextChargeDate == day("2027-08-10"))
        #expect(saved?.lastChargeDate == day("2026-08-10"))
        #expect(saved?.firstChargeDate == day("2026-08-10"))
    }

    @Test func theNextChargeStartsOnePeriodOut() {
        #expect(blank().draft.nextChargeDate == day("2026-09-10"))
    }

    @Test func changingTheCadenceMovesADateNobodyHasChosen() {
        var subject = blank()

        _ = subject.apply(.cadenceChanged(.weekly))
        #expect(subject.draft.nextChargeDate == day("2026-08-17"))

        _ = subject.apply(.cadenceChanged(.annual))
        #expect(subject.draft.nextChargeDate == day("2027-08-10"))
    }

    @Test func achosenDateStaysWhereItWasPut() {
        var subject = blank()

        _ = subject.apply(.nextChargeDateChanged(day("2026-12-01")))
        _ = subject.apply(.cadenceChanged(.annual))

        #expect(subject.draft.nextChargeDate == day("2026-12-01"))
    }

    @Test func theCurrencyStartsAsTheOneTotalsAreShownIn() {
        #expect(blank(currency: "GEL").draft.currency == "GEL")
        #expect(blank(currency: "USD").draft.currency == "USD")
    }

    @Test func currenciesAlreadyInUseAreOfferedWithoutRepeats() {
        let subject = blank(currency: "GEL", knownCurrencies: ["USD", "GEL", "USD", "EUR"])

        #expect(subject.knownCurrencies == ["GEL", "USD", "EUR"])
    }

    @Test func savingHandsBackWhatToWrite() {
        var subject = blank()
        typed(&subject)

        guard case .save(let subscription)? = subject.apply(.saveTapped) else {
            Issue.record("save produced no write")
            return
        }
        #expect(subscription.merchant == "Netflix")
        #expect(subject.apply(.saved(subscription)) == .exit(.saved(subscription)))
    }
}

@Suite("Editing an existing subscription")
struct SubscriptionFormEditingTests {
    @Test func theFormOpensOnWhatIsAlreadyThere() {
        let subject = filled(stored(merchant: "Netflix", amount: "35.99", currency: "USD"))

        #expect(subject.isNew == false)
        #expect(subject.hasChanges == false)
        #expect(subject.draft.merchant == "Netflix")
        #expect(subject.draft.amount == "35.99")
        #expect(subject.draft.currency == "USD")
        #expect(subject.draft.nextChargeDate == day("2026-08-20"))
        #expect(subject.canSave)
    }

    @Test func amendingKeepsTheIdentityAndTheHistory() {
        let charges = [Charge(date: day("2026-07-20"), amount: 35.99, currency: "GEL", conversion: nil)]
        let original = stored(charges: charges)
        var subject = filled(original)

        _ = subject.apply(.merchantChanged("Netflix Family"))
        _ = subject.apply(.amountChanged("41.99"))

        let saved = try? #require(subject.result)
        #expect(saved?.id == original.id)
        #expect(saved?.merchant == "Netflix Family")
        #expect(saved?.amount == Decimal(string: "41.99")!)
        #expect(saved?.charges == charges)
        #expect(saved?.confidence == original.confidence)
    }

    /// Charges are the only honest anchor for these dates, so a subscription that has some keeps
    /// the dates they gave it however its schedule is edited.
    @Test func observedDatesAreNotMovedByTheForm() {
        let charges = [Charge(date: day("2026-07-20"), amount: 35.99, currency: "GEL", conversion: nil)]
        var subject = filled(stored(charges: charges))

        _ = subject.apply(.nextChargeDateChanged(day("2026-11-11")))

        let saved = try? #require(subject.result)
        #expect(saved?.nextChargeDate == day("2026-11-11"))
        #expect(saved?.firstChargeDate == day("2026-05-20"))
        #expect(saved?.lastChargeDate == day("2026-07-20"))
    }

    @Test func aHandEnteredOneKeepsItsDatesDerived() {
        var subject = filled(stored())

        _ = subject.apply(.nextChargeDateChanged(day("2026-11-11")))

        #expect(subject.result?.lastChargeDate == day("2026-10-11"))
    }

    @Test func cancellingFromTheFormIsJustAnotherEdit() {
        var subject = filled(stored(active: true))

        _ = subject.apply(.activeChanged(false))

        #expect(subject.result?.isActive == false)
    }

    @Test func emptyingTheNameBlocksSaving() {
        var subject = filled(stored())

        _ = subject.apply(.merchantChanged(""))

        #expect(subject.canSave == false)
    }
}

@Suite("Leaving the form")
struct SubscriptionFormExitTests {
    @Test func anUntouchedFormClosesWithoutAsking() {
        var subject = blank()

        #expect(subject.apply(.cancelTapped) == .exit(.cancelled))
        #expect(subject.isConfirmingDiscard == false)
    }

    @Test func atouchedFormAsksBeforeThrowingTheTypingAway() {
        var subject = blank()
        typed(&subject)

        #expect(subject.apply(.cancelTapped) == nil)
        #expect(subject.isConfirmingDiscard)
        #expect(subject.apply(.discardConfirmed) == .exit(.cancelled))
    }

    @Test func keepingEditingLeavesTheTypingAlone() {
        var subject = blank()
        typed(&subject)
        _ = subject.apply(.cancelTapped)

        #expect(subject.apply(.discardDismissed) == nil)
        #expect(subject.isConfirmingDiscard == false)
        #expect(subject.draft.merchant == "Netflix")
    }

    @Test func typingSomethingAndTakingItBackIsNotAChange() {
        var subject = blank()

        _ = subject.apply(.merchantChanged("Netflix"))
        _ = subject.apply(.merchantChanged(""))

        #expect(subject.hasChanges == false)
        #expect(subject.apply(.cancelTapped) == .exit(.cancelled))
    }
}

@Suite("Merchant suggestions in the form")
struct SubscriptionFormSuggestionTests {
    @Test func typingAsksForSuggestions() {
        var subject = blank()

        #expect(subject.apply(.merchantChanged("netf")) == .suggest("netf"))
        #expect(subject.apply(.suggestionsLoaded(["Netflix"])) == nil)
        #expect(subject.suggestions == ["Netflix"])
    }

    @Test func takingOneFillsTheFieldAndClearsTheRest() {
        var subject = blank()
        _ = subject.apply(.merchantChanged("netf"))
        _ = subject.apply(.suggestionsLoaded(["Netflix"]))

        _ = subject.apply(.suggestionTapped("Netflix"))

        #expect(subject.draft.merchant == "Netflix")
        #expect(subject.suggestions.isEmpty)
    }
}
