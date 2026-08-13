import Core
import Foundation
import Testing

@testable import Settings

@Suite("Bade Pro")
struct ProStateTests {
    private func loaded(price: String? = "₾24.99", isEntitled: Bool = false) -> ProState {
        var state = ProState()
        _ = state.apply(.appeared)
        _ = state.apply(.loaded(price: price, isEntitled: isEntitled))
        return state
    }

    @Test func thePriceComesFromTheStore() {
        let state = loaded()

        #expect(state.price == "₾24.99")
        #expect(!state.isWorking)
        #expect(!state.isStoreUnavailable)
    }

    /// A button that cannot name a price should not be offered as if it could.
    @Test func aStoreThatCannotBeReachedSaysSo() {
        #expect(loaded(price: nil).isStoreUnavailable)
    }

    /// Already bought, and the store still has no price to quote: that is not a broken store.
    @Test func ownedWithoutAPriceIsNotAnUnreachableStore() {
        let state = loaded(price: nil, isEntitled: true)

        #expect(!state.isStoreUnavailable)
    }

    @Test func buyingTellsTheAppThatHoldsTheEntitlement() {
        var state = loaded()

        #expect(state.apply(.buyTapped) == .buy)
        #expect(state.isWorking)
        #expect(state.apply(.finished(.bought)) == .report(.unlocked))
        #expect(state.isEntitled)
        #expect(!state.isWorking)
    }

    /// Changing your mind is not a failure and nothing should be said about it.
    @Test func cancellingSaysNothing() {
        var state = loaded()
        _ = state.apply(.buyTapped)

        #expect(state.apply(.finished(.cancelled)) == nil)
        #expect(!state.hasFailed)
        #expect(!state.isEntitled)
        #expect(!state.isWorking)
    }

    @Test func aFailedPurchaseIsSaidOnceAndClearsOnTheNextTry() {
        var state = loaded()
        _ = state.apply(.buyTapped)
        _ = state.apply(.finished(.failed))

        #expect(state.hasFailed)
        #expect(!state.isEntitled)

        _ = state.apply(.buyTapped)
        #expect(!state.hasFailed)
    }

    @Test func restoringAPurchaseUnlocksWithoutPayingAgain() {
        var state = loaded()

        #expect(state.apply(.restoreTapped) == .restore)
        #expect(state.apply(.restored(true)) == .report(.unlocked))
        #expect(state.isEntitled)
    }

    /// Nothing to restore is not an error, but it cannot be silent either — the button would look
    /// broken.
    @Test func restoringNothingSaysSoWithoutCallingItAFailure() {
        var state = loaded()
        _ = state.apply(.restoreTapped)
        _ = state.apply(.restored(false))

        #expect(state.foundNothingToRestore)
        #expect(!state.hasFailed)
        #expect(!state.isEntitled)
    }

    /// Double taps arrive while the sheet is opening, and each would start another purchase.
    @Test func tappingTwiceDoesNotBuyTwice() {
        var state = loaded()
        _ = state.apply(.buyTapped)

        #expect(state.apply(.buyTapped) == nil)
        #expect(state.apply(.restoreTapped) == nil)
    }

    @Test func whatIsOwnedIsNotForSaleAgain() {
        var state = loaded(isEntitled: true)

        #expect(state.apply(.buyTapped) == nil)
    }
}
