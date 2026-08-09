import Core
import Foundation
import Testing

@testable import Import

private func file() -> StatementFile {
    StatementFile(name: "BOG_statement.pdf", byteCount: 1_258_291, data: Data("x".utf8))
}

private func detected(_ merchant: String, _ amount: String, _ currency: String = "GEL")
    -> DetectedSubscription
{
    DetectedSubscription(
        merchant: merchant, amount: Decimal(string: amount)!, currency: currency, cadence: .monthly,
        occurrences: [], nextChargeDate: .distantPast, confidence: .confident, priceChanges: [])
}

private func result(_ count: Int, transactions: Int = 1418) -> ImportResult {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let end = calendar.date(from: DateComponents(year: 2026, month: 6, day: 30))!
    return ImportResult(
        detected: (0..<count).map { detected("M\($0)", "10.00") },
        rates: RateBook(), transactionCount: transactions, period: start...end)
}

@Suite("Parsing state machine")
struct ParsingStateTests {
    @Test func readsTheStatementWhenItAppears() {
        var state = ParsingState(file: file())
        let effect = state.apply(.appeared)

        #expect(state.phase == .reading)
        #expect(effect == .read(file().data))
    }

    @Test func fileDetailsResolveOnlyAfterReading() {
        var state = ParsingState(file: file())
        #expect(!state.isDetailsResolved)

        _ = state.apply(.read(result(3)))
        #expect(state.isDetailsResolved)
        #expect(state.transactionCount == 1418)
        #expect(state.monthCount == 6)
    }

    @Test func revealsRowsOneAtATime() {
        var state = ParsingState(file: file())
        var effect = state.apply(.read(result(3)))

        #expect(state.phase == .revealing)
        #expect(state.revealedCount == 0)
        #expect(effect == .scheduleReveal(ParsingTiming.interval(forRows: 3)))

        effect = state.apply(.revealNext)
        #expect(state.revealed.count == 1)
        effect = state.apply(.revealNext)
        #expect(state.revealed.count == 2)

        effect = state.apply(.revealNext)
        #expect(state.revealed.count == 3)
        #expect(effect == .scheduleCompletion(ParsingTiming.completionPause))
    }

    @Test func finishesAfterThePause() {
        var state = ParsingState(file: file())
        _ = state.apply(.read(result(2)))
        _ = state.apply(.revealNext)
        _ = state.apply(.revealNext)

        let effect = state.apply(.completed)
        #expect(state.phase == .finished)
        #expect(effect == .finish(state.found, state.rates))
    }

    @Test func progressWalksTheStatementMonths() {
        var state = ParsingState(file: file())
        _ = state.apply(.read(result(6)))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        #expect(state.progress == 0)
        for _ in 0..<3 { _ = state.apply(.revealNext) }
        #expect(state.progress == 0.5)
        #expect(calendar.component(.month, from: state.currentMonth!) == 4)

        for _ in 0..<3 { _ = state.apply(.revealNext) }
        #expect(state.progress == 1)
    }

    @Test func aStatementWithNothingFoundFinishesImmediately() {
        var state = ParsingState(file: file())
        let effect = state.apply(.read(result(0)))

        #expect(state.phase == .finished)
        #expect(effect == .finish([], state.rates))
    }

    @Test(arguments: [ImportError.unreadableFile, .unrecognisedFormat, .tooFewTransactions])
    func surfacesEachFailure(error: ImportError) {
        var state = ParsingState(file: file())
        let effect = state.apply(.readFailed(error))

        #expect(state.phase == .failed(error))
        #expect(state.failure == error)
        #expect(effect == nil)
    }

    @Test func ignoresRevealTicksAfterFinishing() {
        var state = ParsingState(file: file())
        _ = state.apply(.read(result(1)))
        _ = state.apply(.revealNext)
        _ = state.apply(.completed)

        let effect = state.apply(.revealNext)
        #expect(state.revealedCount == 1)
        #expect(effect == nil)
    }

    @Test func pacingIsCappedForLongStatements() {
        #expect(ParsingTiming.interval(forRows: 5) == ParsingTiming.perRow)
        #expect(ParsingTiming.interval(forRows: 40) < ParsingTiming.perRow)
        #expect(ParsingTiming.interval(forRows: 40) * 40 <= ParsingTiming.maximumReveal)
    }
}

@Suite("Found grouping")
struct FoundGroupingTests {
    @Test func collapsesLookAlikesButKeepsDistinctOnes() {
        let groups = [
            detected("Apple", "11.99", "USD"), detected("Apple", "5.00", "USD"),
            detected("Apple", "5.00", "USD"), detected("Apple", "5.00", "USD"),
            detected("Spotify", "15.20"),
        ].foundGroups

        #expect(groups.count == 3)
        #expect(groups.map(\.merchant) == ["Apple", "Apple", "Spotify"])
        #expect(groups.map(\.count) == [1, 3, 1])
        #expect(groups[0].amount == Decimal(string: "11.99")!)
    }

    @Test func keepsDiscoveryOrderSoRowsNeverReshuffle() {
        let groups = [
            detected("Zoom", "5.00"), detected("Apple", "5.00"), detected("Zoom", "5.00"),
        ].foundGroups

        #expect(groups.map(\.merchant) == ["Zoom", "Apple"])
        #expect(groups.map(\.count) == [2, 1])
    }

    @Test func sameAmountInDifferentCurrenciesStaysSeparate() {
        let groups = [detected("Apple", "5.00", "USD"), detected("Apple", "5.00", "GEL")].foundGroups
        #expect(groups.count == 2)
    }

    @Test func groupsGrowAsRowsReveal() {
        var state = ParsingState(file: file())
        state.found = [
            detected("Apple", "5.00", "USD"), detected("Apple", "5.00", "USD"),
            detected("Spotify", "15.20"),
        ]
        state.phase = .revealing

        _ = state.apply(.revealNext)
        #expect(state.revealedGroups.map(\.count) == [1])
        _ = state.apply(.revealNext)
        #expect(state.revealedGroups.map(\.count) == [2])
        _ = state.apply(.revealNext)
        #expect(state.revealedGroups.map(\.merchant) == ["Apple", "Spotify"])
    }
}
