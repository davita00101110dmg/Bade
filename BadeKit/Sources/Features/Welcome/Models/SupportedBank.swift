import Foundation
import Localization

enum SupportedBank: String, CaseIterable, Identifiable {
    case bog = "BOG"
    case tbc = "TBC"

    var id: String { rawValue }

    var exportSteps: [LocalizedStringResource] {
        switch self {
        case .bog: LocalizedStringResource.exportGuide.bog
        case .tbc: LocalizedStringResource.exportGuide.tbc
        }
    }
}
