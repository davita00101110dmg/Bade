import Foundation

/// Typed access to the catalog, written as `Text(.welcome.title)`. A mistyped key is a compile
/// error rather than a key rendered on screen. One entry here per key in `Localizable.xcstrings`.
extension LocalizedStringResource {
    public static var welcome: WelcomeStrings { WelcomeStrings() }
    public static var exportGuide: ExportGuideStrings { ExportGuideStrings() }

    public struct WelcomeStrings {
        public var title: LocalizedStringResource { string("welcome.title") }
        public var subtitle: LocalizedStringResource { string("welcome.subtitle") }
        public var importStatement: LocalizedStringResource { string("welcome.import") }
        public var addManually: LocalizedStringResource { string("welcome.addManually") }
        public var guideTitle: LocalizedStringResource { string("welcome.guide.title") }
        public var guideBankPicker: LocalizedStringResource { string("welcome.guide.bankPicker") }
        public var privacyLine1: LocalizedStringResource { string("welcome.privacy.line1") }
        public var privacyLine2: LocalizedStringResource { string("welcome.privacy.line2") }
    }

    public struct ExportGuideStrings {
        public var bog: [LocalizedStringResource] {
            [
                string("welcome.guide.bog.1"), string("welcome.guide.bog.2"),
                string("welcome.guide.bog.3"),
            ]
        }
        public var tbc: [LocalizedStringResource] {
            [
                string("welcome.guide.tbc.1"), string("welcome.guide.tbc.2"),
                string("welcome.guide.tbc.3"),
            ]
        }
    }
}

private func string(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.bade.bundleURL))
}
