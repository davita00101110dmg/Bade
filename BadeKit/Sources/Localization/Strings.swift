import Foundation

/// Typed access to the catalog, written as `Text(.welcome.title)`. A mistyped key is a compile
/// error rather than a key rendered on screen. One entry here per key in `Localizable.xcstrings`.
extension LocalizedStringResource {
    public static var welcome: WelcomeStrings { WelcomeStrings() }
    public static var parsing: ParsingStrings { ParsingStrings() }
    public static var review: ReviewStrings { ReviewStrings() }
    public static var cadence: CadenceStrings { CadenceStrings() }
    public static var subscriptions: SubscriptionsStrings { SubscriptionsStrings() }

    public struct WelcomeStrings {
        public var title: LocalizedStringResource { string("welcome.title") }
        public var subtitle: LocalizedStringResource { string("welcome.subtitle") }
        public var importStatement: LocalizedStringResource { string("welcome.import") }
        public var addManually: LocalizedStringResource { string("welcome.addManually") }
        public var guideTitle: LocalizedStringResource { string("welcome.guide.title") }

        /// Deliberately bank-agnostic: constraint 6 keeps bank specifics inside a parser.
        public var guideSteps: [LocalizedStringResource] {
            [string("welcome.guide.1"), string("welcome.guide.2"), string("welcome.guide.3")]
        }
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

    public struct ReviewStrings {
        public var title: LocalizedStringResource { string("review.title") }
        public var tierConfident: LocalizedStringResource { string("review.tier.confident") }
        public var tierProbable: LocalizedStringResource { string("review.tier.probable") }
        public var tierUncertain: LocalizedStringResource { string("review.tier.uncertain") }
        public var confidentHint: LocalizedStringResource { string("review.tier.confidentHint") }
        public var probableHint: LocalizedStringResource { string("review.tier.probableHint") }
        public var priceChanged: LocalizedStringResource { string("review.priceChanged") }
        public var isSubscription: LocalizedStringResource { string("review.isSubscription") }
        public var notOne: LocalizedStringResource { string("review.notOne") }
        public var saveFailed: LocalizedStringResource { string("review.saveFailed") }
        public var close: LocalizedStringResource { string("review.close") }

        public func summary(_ count: Int, _ monthly: String) -> LocalizedStringResource {
            string("review.summary \(count) \(monthly)")
        }
        public func caption(_ charges: Int, _ detail: String) -> LocalizedStringResource {
            string("review.caption \(charges) \(detail)")
        }
        public func confirm(_ count: Int) -> LocalizedStringResource {
            string("review.confirm \(count)")
        }
        public func tierCount(_ tier: String, _ count: Int) -> LocalizedStringResource {
            string("review.tierCount \(tier) \(count)")
        }
    }

    public struct SubscriptionsStrings {
        public var perMonth: LocalizedStringResource { string("subscriptions.perMonth") }
        public var all: LocalizedStringResource { string("subscriptions.all") }
        public var sortByCost: LocalizedStringResource { string("subscriptions.sort.cost") }
        public var sortByName: LocalizedStringResource { string("subscriptions.sort.name") }
        public var sortByNextCharge: LocalizedStringResource {
            string("subscriptions.sort.nextCharge")
        }
        public var sortLabel: LocalizedStringResource { string("subscriptions.sortLabel") }
        public var importStatement: LocalizedStringResource { string("subscriptions.import") }
        public var loadFailed: LocalizedStringResource { string("subscriptions.loadFailed") }
        public var separator: LocalizedStringResource { string("subscriptions.separator") }
        public var delete: LocalizedStringResource { string("subscriptions.delete") }
        public var deleteAll: LocalizedStringResource { string("subscriptions.deleteAll") }
        public var deleteAllTitle: LocalizedStringResource {
            string("subscriptions.deleteAllTitle")
        }
        public var deleteAllMessage: LocalizedStringResource {
            string("subscriptions.deleteAllMessage")
        }
        public var cancel: LocalizedStringResource { string("subscriptions.cancel") }

        public func yearAndCount(_ annual: String, _ count: Int) -> LocalizedStringResource {
            string("subscriptions.yearAndCount \(annual) \(count)")
        }
        public func unconvertible(_ count: Int) -> LocalizedStringResource {
            string("subscriptions.unconvertible \(count)")
        }
    }

    /// Localization has no dependencies, so cadences are named rather than keyed off `Cadence`.
    public struct CadenceStrings {
        public var weekly: LocalizedStringResource { string("cadence.weekly") }
        public var monthly: LocalizedStringResource { string("cadence.monthly") }
        public var quarterly: LocalizedStringResource { string("cadence.quarterly") }
        public var semiannual: LocalizedStringResource { string("cadence.semiannual") }
        public var annual: LocalizedStringResource { string("cadence.annual") }
    }
}

extension String {
    /// Resolves against the view's locale rather than the process locale, so a preview in Georgian
    /// renders Georgian. Needed wherever a localised value has to become a `String` to be
    /// interpolated or styled.
    public static func badeLocalized(_ resource: LocalizedStringResource, in locale: Locale)
        -> String
    {
        var resolved = resource
        resolved.locale = locale
        return String(localized: resolved)
    }
}

private func string(_ key: String.LocalizationValue) -> LocalizedStringResource {
    LocalizedStringResource(key, bundle: .atURL(Bundle.bade.bundleURL))
}
