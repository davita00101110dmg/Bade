import Foundation
import Import
import Testing

@testable import AppRoot

private func file(_ name: String = "statement.pdf") -> StatementFile {
    StatementFile(name: name, byteCount: 4, data: Data([1, 2, 3, 4]))
}

/// The state machine that took import down twice, and until now could not be asserted about at all:
/// it lived as `@State` and private functions inside a `View`, where the only way to test it was a
/// simulator and a thumb.
@MainActor
@Suite("What is on top of the app")
struct AppPresentationTests {
    /// No wait to sit through — every test that turns on the gap passes `.zero`.
    private func subject(_ current: AppPresentation.Kind? = nil) -> AppPresentation {
        AppPresentation(current: current, dismissalGap: .zero)
    }

    @Test func presentsImmediatelyWhenNothingIsUp() {
        let presentation = subject()

        presentation.present(.pro)

        #expect(presentation.current == .pro)
        #expect(presentation.pending == nil)
    }

    /// The whole point: what is up leaves first, and the next one waits rather than being asked for
    /// while SwiftUI is still taking the last one away.
    @Test func queuesBehindSomethingThatReportsItsOwnDismissal() {
        let presentation = subject(.importing(file()))

        presentation.present(.pickingFile)

        #expect(presentation.current == nil, "the cover is told to leave")
        #expect(presentation.pending == .pickingFile, "and the picker waits for it")
    }

    @Test func presentsTheQueuedOneOnceTheDismissalFinishes() {
        let presentation = subject(.importing(file()))
        presentation.present(.pickingFile)

        presentation.dismissalFinished()

        #expect(presentation.current == .pickingFile)
        #expect(presentation.pending == nil)
    }

    @Test func aDismissalWithNothingQueuedChangesNothing() {
        let presentation = subject(.pro)
        presentation.dismissCurrent()

        presentation.dismissalFinished()

        #expect(presentation.current == nil)
    }

    /// An alert and the file importer never report going away, so the only signal is a beat.
    @Test func waitsOutTheGapBehindSomethingThatReportsNothing() async throws {
        let presentation = subject(.nothingWasNew)

        presentation.present(.pickingFile)
        #expect(presentation.current == nil, "not while the alert is still leaving")

        try await Task.sleep(for: .milliseconds(50))
        #expect(presentation.current == .pickingFile)
    }

    /// The file importer clears the flag as it begins dismissing, so by the time its completion runs
    /// nothing is recorded as up while UIKit is still animating the picker away. Presenting straight
    /// into that is refused silently and wedges the stack — so this waits even with nothing current.
    @Test func presentAfterDismissalWaitsEvenWhenNothingIsRecordedAsUp() async throws {
        let presentation = subject()

        presentation.presentAfterDismissal(.importing(file()))
        #expect(presentation.current == nil, "the picker is still going, whatever this thinks")

        try await Task.sleep(for: .milliseconds(50))
        #expect(presentation.current == .importing(file()))
    }

    /// The importer sets its own flag false *after* the cover has been recorded, so a blind clear
    /// would take the cover down with it.
    @Test func abindingOnlyClearsThePresentationItNames() {
        let presentation = subject(.importing(file()))

        presentation.dismiss(.pickingFile)

        #expect(presentation.current == .importing(file()), "another one's dismissal is not ours")
    }

    /// Deliberate: this is the recovery path if a presentation is ever dropped, and what a second
    /// tap on a dead Import button has to do.
    @Test func askingForWhatIsAlreadyShowingRepresentsIt() {
        let presentation = subject(.pickingFile)

        presentation.present(.pickingFile)

        #expect(presentation.pending == .pickingFile)
        presentation.dismissalFinished()
        #expect(presentation.current == .pickingFile)
    }

    @Test(arguments: [
        (AppPresentation.Kind.pro, true), (.askingAboutReminders, true), (.addingManually, true),
        (.pickingFile, false), (.storeWasReset, false), (.nothingWasNew, false),
    ])
    func eachKindKnowsWhetherItReportsItsDismissal(_ kind: AppPresentation.Kind, _ reports: Bool) {
        #expect(kind.reportsItsDismissal == reports)
    }
}
