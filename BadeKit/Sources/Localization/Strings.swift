import Foundation

/// Typed access to the catalog, written as `Text(.welcome.title)`. A mistyped key is a compile
/// error rather than a key rendered on screen. One entry here per key in `Localizable.xcstrings`.
extension LocalizedStringResource {
    public static var welcome: WelcomeStrings { WelcomeStrings() }
    public static var parsing: ParsingStrings { ParsingStrings() }
    public static var review: ReviewStrings { ReviewStrings() }
    public static var cadence: CadenceStrings { CadenceStrings() }
    public static var subscriptions: SubscriptionsStrings { SubscriptionsStrings() }
    public static var detail: DetailStrings { DetailStrings() }
    public static var form: FormStrings { FormStrings() }
    public static var currency: CurrencyStrings { CurrencyStrings() }
    public static var upcoming: UpcomingStrings { UpcomingStrings() }
    public static var settings: SettingsStrings { SettingsStrings() }
    public static var pro: ProStrings { ProStrings() }
    public static var locked: LockedStrings { LockedStrings() }
    public static var reminder: ReminderStrings { ReminderStrings() }
    public static var store: StoreStrings { StoreStrings() }
    public static var common: CommonStrings { CommonStrings() }
    public static var widget: WidgetStrings { WidgetStrings() }
    public static var importing: ImportStrings { ImportStrings() }
    public static var reminderPrompt: ReminderPromptStrings { ReminderPromptStrings() }

    /// Shown wherever a feature is held back for Bade Pro.
    public struct LockedStrings {
        public var title: LocalizedStringResource { string("locked.title") }
        public var action: LocalizedStringResource { string("locked.action") }
    }

    public struct ProStrings {
        public var title: LocalizedStringResource { string("pro.title") }
        /// Marks a row that leads here rather than doing anything itself.
        public var badge: LocalizedStringResource { string("pro.badge") }
        public var reminders: LocalizedStringResource { string("pro.reminders") }
        public var remindersDetail: LocalizedStringResource { string("pro.remindersDetail") }
        public var tagline: LocalizedStringResource { string("pro.tagline") }
        public var blurb: LocalizedStringResource { string("pro.blurb") }
        public var unlock: LocalizedStringResource { string("pro.unlock") }
        public var restore: LocalizedStringResource { string("pro.restore") }
        public var owned: LocalizedStringResource { string("pro.owned") }
        public var ownedDetail: LocalizedStringResource { string("pro.ownedDetail") }
        public var failed: LocalizedStringResource { string("pro.failed") }
        public var nothingToRestore: LocalizedStringResource { string("pro.nothingToRestore") }
        public var storeUnavailable: LocalizedStringResource { string("pro.storeUnavailable") }

        /// The store's own formatting, so no price is ever written into Bade.
        public func unlockPrice(_ price: String) -> LocalizedStringResource {
            string("pro.unlockPrice \(price)")
        }
        public var included: LocalizedStringResource { string("pro.included") }
        public var fx: LocalizedStringResource { string("pro.fx") }
        public var fxDetail: LocalizedStringResource { string("pro.fxDetail") }
        public var alerts: LocalizedStringResource { string("pro.alerts") }
        public var alertsDetail: LocalizedStringResource { string("pro.alertsDetail") }
        public var trends: LocalizedStringResource { string("pro.trends") }
        public var trendsDetail: LocalizedStringResource { string("pro.trendsDetail") }
        public var categories: LocalizedStringResource { string("pro.categories") }
        public var categoriesDetail: LocalizedStringResource { string("pro.categoriesDetail") }
        public var widgets: LocalizedStringResource { string("pro.widgets") }
        public var widgetsDetail: LocalizedStringResource { string("pro.widgetsDetail") }
        public var themes: LocalizedStringResource { string("pro.themes") }
        public var themesDetail: LocalizedStringResource { string("pro.themesDetail") }
    }

    /// The currency picker is a shared control, so its copy is not any one screen's.
    public struct CurrencyStrings {
        public var title: LocalizedStringResource { string("currency.title") }
        public var known: LocalizedStringResource { string("currency.known") }
        public var all: LocalizedStringResource { string("currency.all") }
        public var search: LocalizedStringResource { string("currency.search") }
    }

    public struct UpcomingStrings {
        public var title: LocalizedStringResource { string("upcoming.title") }
        public var thisMonth: LocalizedStringResource { string("upcoming.thisMonth") }
        public var total: LocalizedStringResource { string("upcoming.total") }
        public var showMonth: LocalizedStringResource { string("upcoming.showMonth") }
        public var nothingThatDay: LocalizedStringResource { string("upcoming.nothingThatDay") }
        public var nothing: LocalizedStringResource { string("upcoming.nothing") }
        public var nothingEver: LocalizedStringResource { string("upcoming.nothingEver") }
        public var previous: LocalizedStringResource { string("upcoming.previous") }
        public var next: LocalizedStringResource { string("upcoming.next") }
        public var loadFailed: LocalizedStringResource { string("upcoming.loadFailed") }
    }

    public struct SettingsStrings {
        public var title: LocalizedStringResource { string("settings.title") }
        public var display: LocalizedStringResource { string("settings.display") }
        public var language: LocalizedStringResource { string("settings.language") }
        /// Each language named in itself; the same word in either locale.
        public var languageEnglish: LocalizedStringResource { string("settings.language.en") }
        public var languageGeorgian: LocalizedStringResource { string("settings.language.ka") }
        public var data: LocalizedStringResource { string("settings.data") }
        public var exportJSON: LocalizedStringResource { string("settings.exportJSON") }
        public var exportCSV: LocalizedStringResource { string("settings.exportCSV") }
        public var exportName: LocalizedStringResource { string("settings.exportName") }
        public var about: LocalizedStringResource { string("settings.about") }
        public var rates: LocalizedStringResource { string("settings.rates") }
        public var ratesFooter: LocalizedStringResource { string("settings.ratesFooter") }
        public var optionSystem: LocalizedStringResource { string("settings.option.system") }
        public var appearance: LocalizedStringResource { string("settings.appearance") }
        public var appearanceLight: LocalizedStringResource { string("settings.appearance.light") }
        public var appearanceDark: LocalizedStringResource { string("settings.appearance.dark") }
        public var textSize: LocalizedStringResource { string("settings.textSize") }
        public var textSizeSmallest: LocalizedStringResource { string("settings.textSize.smallest") }
        public var textSizeSmaller: LocalizedStringResource { string("settings.textSize.smaller") }
        public var textSizeStandard: LocalizedStringResource { string("settings.textSize.standard") }
        public var textSizeLarger: LocalizedStringResource { string("settings.textSize.larger") }
        public var textSizeLargest: LocalizedStringResource { string("settings.textSize.largest") }
        public var weekStart: LocalizedStringResource { string("settings.weekStart") }
        public var weekStartMonday: LocalizedStringResource { string("settings.weekStart.monday") }
        public var weekStartSunday: LocalizedStringResource { string("settings.weekStart.sunday") }
        public var defaultBadge: LocalizedStringResource { string("settings.defaultBadge") }
        public var defaultFooter: LocalizedStringResource { string("settings.defaultFooter") }
        public var reminders: LocalizedStringResource { string("settings.reminders") }
        public var remindMe: LocalizedStringResource { string("settings.remindMe") }
        public var reminderTime: LocalizedStringResource { string("settings.reminderTime") }
        public var remindersFooter: LocalizedStringResource { string("settings.remindersFooter") }
        public var remindersPro: LocalizedStringResource { string("settings.remindersPro") }
        public var remindersDenied: LocalizedStringResource { string("settings.remindersDenied") }
        public var reminderOff: LocalizedStringResource { string("settings.reminderOff") }
        public var reminderSameDay: LocalizedStringResource { string("settings.reminderSameDay") }
        public var reminderOneDay: LocalizedStringResource { string("settings.reminderOneDay") }
        public var reminderTwoDays: LocalizedStringResource { string("settings.reminderTwoDays") }
        public var reminderThreeDays: LocalizedStringResource {
            string("settings.reminderThreeDays")
        }

        public func version(_ version: String) -> LocalizedStringResource {
            string("settings.version \(version)")
        }
    }

    /// The ask, offered once the first import has landed and the total has been seen.
    public struct ReminderPromptStrings {
        public var title: LocalizedStringResource { string("reminderPrompt.title") }
        public var blurb: LocalizedStringResource { string("reminderPrompt.blurb") }
        public var allow: LocalizedStringResource { string("reminderPrompt.allow") }
        public var notNow: LocalizedStringResource { string("reminderPrompt.notNow") }
    }

    /// Said once, when what was stored could not be read and the app had to start again.
    public struct StoreStrings {
        public var resetTitle: LocalizedStringResource { string("store.resetTitle") }
        public var resetMessage: LocalizedStringResource { string("store.resetMessage") }
    }

    /// Words that belong to no one screen. Kept small on purpose.
    public struct CommonStrings {
        public var ok: LocalizedStringResource { string("common.ok") }
    }

    /// The home screen widget, which has room for very little and must choose well.
    public struct WidgetStrings {
        /// Named for what it shows rather than for the app; the gallery already says "Bade".
        public var name: LocalizedStringResource { string("widget.name") }
        public var description: LocalizedStringResource { string("widget.description") }
        public var thisMonth: LocalizedStringResource { string("widget.thisMonth") }
        public var stillComing: LocalizedStringResource { string("widget.stillComing") }
        public var locked: LocalizedStringResource { string("widget.locked") }
        public var empty: LocalizedStringResource { string("widget.empty") }
        /// Nothing left to be charged this month, which is worth saying rather than showing zero.
        public var allCharged: LocalizedStringResource { string("widget.allCharged") }

        public func toGo(_ amount: String) -> LocalizedStringResource {
            string("widget.toGo \(amount)")
        }
    }

    /// Said after an import that changed nothing, because silence reads as failure.
    public struct ImportStrings {
        public var nothingNewTitle: LocalizedStringResource { string("import.nothingNewTitle") }
        public var nothingNewMessage: LocalizedStringResource { string("import.nothingNewMessage") }
    }

    /// A reminder's title says only when. What is charging, and for how much, is the body's job.
    public struct ReminderStrings {
        public var today: LocalizedStringResource { string("reminder.today") }
        public var tomorrow: LocalizedStringResource { string("reminder.tomorrow") }
        public func onDay(_ weekday: String) -> LocalizedStringResource {
            string("reminder.onDay \(weekday)")
        }
    }

    public struct FormStrings {
        public var newTitle: LocalizedStringResource { string("form.title.new") }
        public var editTitle: LocalizedStringResource { string("form.title.edit") }
        public var save: LocalizedStringResource { string("form.save") }
        public var cancel: LocalizedStringResource { string("form.cancel") }
        public var service: LocalizedStringResource { string("form.service") }
        public var servicePrompt: LocalizedStringResource { string("form.servicePrompt") }
        public var suggestions: LocalizedStringResource { string("form.suggestions") }
        public var price: LocalizedStringResource { string("form.price") }
        public var amount: LocalizedStringResource { string("form.amount") }
        public var billing: LocalizedStringResource { string("form.billing") }
        public var cadence: LocalizedStringResource { string("form.cadence") }
        public var active: LocalizedStringResource { string("form.active") }
        public var activeFooter: LocalizedStringResource { string("form.activeFooter") }
        public var discardTitle: LocalizedStringResource { string("form.discardTitle") }
        public var discardMessage: LocalizedStringResource { string("form.discardMessage") }
        public var discard: LocalizedStringResource { string("form.discard") }
        public var keepEditing: LocalizedStringResource { string("form.keepEditing") }
    }

    public struct DetailStrings {
        public var title: LocalizedStringResource { string("detail.title") }
        public var history: LocalizedStringResource { string("detail.history") }
        public var nextCharge: LocalizedStringResource { string("detail.nextCharge") }
        public var aYear: LocalizedStringResource { string("detail.aYear") }
        public var firstCharge: LocalizedStringResource { string("detail.firstCharge") }
        public var delete: LocalizedStringResource { string("detail.delete") }
        public var deleteTitle: LocalizedStringResource { string("detail.deleteTitle") }
        public var deleteMessage: LocalizedStringResource { string("detail.deleteMessage") }
        public var cancel: LocalizedStringResource { string("detail.cancel") }
        public var noHistory: LocalizedStringResource { string("detail.noHistory") }
        public var fxTitle: LocalizedStringResource { string("detail.fx.title") }
        public var fxPaid: LocalizedStringResource { string("detail.fx.paid") }
        public var fxBankRate: LocalizedStringResource { string("detail.fx.bankRate") }
        public var fxSchemeRate: LocalizedStringResource { string("detail.fx.schemeRate") }
        public var fxOfficialRate: LocalizedStringResource { string("detail.fx.officialRate") }
        public var fxRateGap: LocalizedStringResource { string("detail.fx.rateGap") }
        public var fxNoRate: LocalizedStringResource { string("detail.fx.noRate") }

        public func fxNoConversion(_ currency: String) -> LocalizedStringResource {
            string("detail.fx.noConversion \(currency)")
        }

        public func billedIn(_ cadence: String, _ currency: String) -> LocalizedStringResource {
            string("detail.billedIn \(cadence) \(currency)")
        }
        public func priceChange(_ month: String) -> LocalizedStringResource {
            string("detail.priceChange \(month)")
        }
    }

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
        public var nothingTitle: LocalizedStringResource { string("parsing.nothingTitle") }
        public var nothingMessage: LocalizedStringResource { string("parsing.nothingMessage") }

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
        public var tierEnded: LocalizedStringResource { string("review.tier.ended") }
        public var endedHint: LocalizedStringResource { string("review.tier.endedHint") }
        public var confidentHint: LocalizedStringResource { string("review.tier.confidentHint") }
        public var probableHint: LocalizedStringResource { string("review.tier.probableHint") }
        public var priceChanged: LocalizedStringResource { string("review.priceChanged") }
        public func ended(_ month: String) -> LocalizedStringResource {
            string("review.ended \(month)")
        }
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
        public var title: LocalizedStringResource { string("subscriptions.title") }
        public var perMonth: LocalizedStringResource { string("subscriptions.perMonth") }
        public var all: LocalizedStringResource { string("subscriptions.all") }
        public var sortByCost: LocalizedStringResource { string("subscriptions.sort.cost") }
        public var sortByName: LocalizedStringResource { string("subscriptions.sort.name") }
        public var sortByNextCharge: LocalizedStringResource {
            string("subscriptions.sort.nextCharge")
        }
        public var sortLabel: LocalizedStringResource { string("subscriptions.sortLabel") }
        public var importStatement: LocalizedStringResource { string("subscriptions.import") }
        public var add: LocalizedStringResource { string("subscriptions.add") }
        /// Shared with detail: the same act, offered from the list and from the screen itself.
        public var edit: LocalizedStringResource { string("subscriptions.edit") }
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
        public var noLongerCharged: LocalizedStringResource {
            string("subscriptions.noLongerCharged")
        }
        public var nothingCharging: LocalizedStringResource {
            string("subscriptions.nothingCharging")
        }
        /// Shared with detail: the same act, offered from the list and from the screen itself.
        public var markCancelled: LocalizedStringResource {
            string("subscriptions.markCancelled")
        }
        public var markActive: LocalizedStringResource { string("subscriptions.markActive") }

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
