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
}
