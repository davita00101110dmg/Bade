import Core
import Foundation
import Localization

/// Duplicated from Import rather than shared: feature modules never import each other, and
/// `Localization` has no dependencies, so it cannot know what a `Cadence` is.
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
}
