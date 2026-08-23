import Core
import Foundation

/// How a billing rhythm is written, in one place.
///
/// It lived twice — once under Subscriptions and once under Import/Review — because feature modules
/// never import each other, and the note above each copy said `Localization` could not know what a
/// `Cadence` is. That was a choice rather than a constraint: `Core` depends on nothing, so this
/// module can depend on it without a cycle. The two copies had already drifted apart by a method.
extension Cadence {
    public var localizedName: LocalizedStringResource {
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
    public func billedPhrase(_ amount: String) -> LocalizedStringResource? {
        switch self {
        case .monthly: nil
        case .weekly: .subscriptions.billedWeekly(amount)
        case .quarterly: .subscriptions.billedQuarterly(amount)
        case .semiannual: .subscriptions.billedSemiannual(amount)
        case .annual: .subscriptions.billedAnnual(amount)
        }
    }
}
