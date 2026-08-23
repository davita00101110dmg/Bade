import Core
import Foundation
import Localization

/// Shared by Detail and the form, which is why it sits at the module root. Duplicated from Import
/// rather than shared with it: feature modules never import each other, and `Localization` has no
/// dependencies, so it cannot know what a `Cadence` is.
extension Cadence {
    var localizedName: LocalizedStringResource {
        switch self {
        case .weekly: .cadence.weekly
        case .monthly: .cadence.monthly
        case .quarterly: .cadence.quarterly
        case .semiannual: .cadence.semiannual
        case .annual: .cadence.annual
        }
    }

    /// The real price and how often it is charged — "$379.75 a year". The list levels every cadence
    /// into a month, so an annual subscription shows a figure nobody was ever charged; saying what
    /// it actually costs is what makes the levelled one read as a share of it.
    ///
    /// Monthly says nothing: there the figure on the right *is* the price, and a row explaining
    /// that would be noise on the common case.
    func billedPhrase(_ amount: String) -> LocalizedStringResource? {
        switch self {
        case .monthly: nil
        case .weekly: .subscriptions.billedWeekly(amount)
        case .quarterly: .subscriptions.billedQuarterly(amount)
        case .semiannual: .subscriptions.billedSemiannual(amount)
        case .annual: .subscriptions.billedAnnual(amount)
        }
    }
}
