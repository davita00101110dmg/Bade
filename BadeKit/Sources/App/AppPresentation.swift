import Foundation
import Import
import Observation

/// The one thing on top of the app, and the one waiting to take its place.
///
/// This has broken twice, in the same way both times, and each time it took import with it
/// permanently until the app was relaunched. First seven independent booleans let two presentations
/// be asked for at once — SwiftUI drops the loser without saying so, leaving its flag set, after
/// which every later request set `true` to `true`, which is not a change. Then, with that fixed, the
/// file importer handed straight to the cover while UIKit was still animating the picker away, which
/// SwiftUI also refuses silently, and the presentation stack stayed occupied for good.
///
/// One value makes two at once unrepresentable. Living here rather than in the root makes the rest
/// testable: it is a state machine, and inside a `View` there was no way to assert anything about it.
@MainActor
@Observable
final class AppPresentation {
    enum Kind: Equatable {
        case pickingFile
        case importing(StatementFile)
        case pro
        case askingAboutReminders
        case addingManually
        case storeWasReset
        case nothingWasNew

        /// Whether this one calls back once it has finished leaving. A cover and a sheet do; an
        /// alert and the file importer do not, and the only thing to do about those is wait a beat.
        var reportsItsDismissal: Bool {
            switch self {
            case .importing, .pro, .askingAboutReminders, .addingManually: true
            case .pickingFile, .storeWasReset, .nothingWasNew: false
            }
        }
    }

    private(set) var current: Kind?
    /// Asked for while something else was still on screen, and presented the moment that has gone.
    private(set) var pending: Kind?

    /// Long enough for a sheet or a cover to finish leaving. Injected so a test need not wait for it.
    private let dismissalGap: Duration

    init(current: Kind? = nil, dismissalGap: Duration = .milliseconds(350)) {
        self.current = current
        self.dismissalGap = dismissalGap
    }

    /// Asking for something while something else is up is the case that used to break: SwiftUI
    /// cannot present into a view that is still going away, so it silently does nothing.
    ///
    /// Asking for what is already showing works too, and deliberately — that is the recovery path if
    /// a presentation was ever dropped, and it is what a second tap on a dead Import button does.
    func present(_ next: Kind) {
        guard let leaving = current else {
            current = next
            return
        }
        pending = next
        current = nil
        // A cover or a sheet says when it has gone, and waiting for that is exact. An alert and the
        // file importer never say, so for those a beat is the only signal there is.
        if !leaving.reportsItsDismissal { drainAfterTheGap() }
    }

    /// Presents once whatever is leaving has had time to go, whether or not anything is recorded as
    /// being up.
    ///
    /// `current` is not always the truth about the screen. The file importer clears it as it begins
    /// dismissing, so by the time its completion runs the app believes nothing is presented while
    /// UIKit is still animating the picker away — and `present` would go straight into it.
    func presentAfterDismissal(_ next: Kind) {
        current = nil
        pending = next
        drainAfterTheGap()
    }

    /// Called when a presentation has actually finished leaving. Safe when nothing is waiting.
    func dismissalFinished() {
        guard let next = pending else { return }
        pending = nil
        current = next
    }

    /// A `Bool` binding reported that this one went away. Only clears when it is still the one up:
    /// the file importer sets its flag false *after* the next presentation has been recorded.
    func dismiss(_ kind: Kind) {
        guard current == kind else { return }
        current = nil
    }

    /// An item binding reported nil, which only the cover does, and only about itself.
    func dismissCurrent() {
        current = nil
    }

    func isShowing(_ kind: Kind) -> Bool { current == kind }

    var importingFile: StatementFile? {
        guard case .importing(let file) = current else { return nil }
        return file
    }

    private func drainAfterTheGap() {
        Task { @MainActor in
            try? await Task.sleep(for: dismissalGap)
            dismissalFinished()
        }
    }
}
