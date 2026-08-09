import Foundation

/// Typed access to the catalog, written as `Text(.welcome.title)`. A mistyped key is a compile
/// error rather than a key rendered on screen. One entry here per key in `Localizable.xcstrings`.
extension LocalizedStringResource {
    public static var welcome: WelcomeStrings { WelcomeStrings() }
    public static var exportGuide: ExportGuideStrings { ExportGuideStrings() }
    public static var parsing: ParsingStrings { ParsingStrings() }

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

    public struct ParsingStrings {
        public var title: LocalizedStringResource { string("parsing.title") }
        public var found: LocalizedStringResource { string("parsing.found") }
        public var processedHere: LocalizedStringResource { string("parsing.processedHere") }
        public var failed: LocalizedStringResource { string("parsing.failed") }
        public var close: LocalizedStringResource { string("parsing.close") }
        public var chooseAnother: LocalizedStringResource { string("parsing.chooseAnother") }
        public var failureUnreadable: LocalizedStringResource { string("parsing.failure.unreadable") }
        public var failureUnrecognised: LocalizedStringResource { string("parsing.failure.unrecognised") }
        public var failureTooFew: LocalizedStringResource { string("parsing.failure.tooFew") }

        public func occurrences(_ count: Int) -> LocalizedStringResource {
            string("parsing.occurrences \(count)")
        }
        public func months(_ count: Int) -> LocalizedStringResource {
            string("parsing.file.months \(count)")
        }
        public func transactions(_ count: Int) -> LocalizedStringResource {
            string("parsing.file.transactions \(count)")
        }
        public func progress(_ month: String, _ percent: String) -> LocalizedStringResource {
            string("parsing.progress \(month) \(percent)")
        }
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
