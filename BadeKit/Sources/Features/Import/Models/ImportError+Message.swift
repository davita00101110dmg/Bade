import Core
import Foundation
import Localization

extension ImportError {
    public var message: LocalizedStringResource {
        switch self {
        case .unreadableFile: .parsing.failureUnreadable
        case .unrecognisedFormat: .parsing.failureUnrecognised
        case .tooFewTransactions: .parsing.failureTooFew
        }
    }
}
