import Core
import Foundation
import Localization

/// How the list is ordered. Cost first by default: the brief's point is that seeing the biggest
/// charge at the top is what makes someone act.
public enum SubscriptionSort: String, CaseIterable, Identifiable, Sendable {
    case cost
    case name
    case nextCharge

    public var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .cost: .subscriptions.sortByCost
        case .name: .subscriptions.sortByName
        case .nextCharge: .subscriptions.sortByNextCharge
        }
    }
}
