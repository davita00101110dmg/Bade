import Core
import Foundation
import Localization

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
