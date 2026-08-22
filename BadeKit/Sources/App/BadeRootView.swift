import Catalog
import Core
import DesignSystem
import FX
import Import
import Localization
import Notifications
import Persistence
import Pipeline
import Purchases
import Settings
import Subscriptions
import SwiftUI
import TipKit
import UniformTypeIdentifiers
import Upcoming
import Welcome
import Widgets

public struct BadeRootView: View {
    private enum Tabs: Hashable { case subscriptions, upcoming, settings }

    @AppStorage("displayCurrency") private var chosenCurrency = ""
    @AppStorage("language") private var languageCode = BadeLanguage.matchingDevice.rawValue
    @AppStorage("appearance") private var appearanceCode = BadeAppearance.system.rawValue
    @AppStorage("textSize") private var textSizeCode = BadeTextSize.system.rawValue
    @AppStorage("weekStart") private var weekStartCode = BadeWeekStart.system.rawValue
    @AppStorage("fetchesRates") private var fetchesRates = true
    @AppStorage("reminderLead") private var reminderLeadCode = ReminderLead.off.rawValue
    @AppStorage("reminderTime") private var reminderTime = ReminderPreference.defaultTimeOfDay
    /// Asked once and never again, whichever way it was answered.
    @AppStorage("hasAskedAboutReminders") private var hasAskedAboutReminders = false
    /// A cache of the App Store entitlement, written at launch and whenever one arrives, so a
    /// locked screen answers instantly and offline rather than waiting on StoreKit.
    @AppStorage("isPro") private var hasEntitlement = false

    /// Opened once, at launch, and it always opens: what cannot be read is set aside rather than
    /// crashed on.
    @State private var opened: OpenedStore
    /// Seeded from that one opening rather than from a reload, so the notice appears exactly once.
    @State private var isSayingStoreWasReset: Bool
    @State private var hasSubscriptions = false
    @State private var isReady = false
    @State private var isPickingFile = false
    @State private var isAddingManually = false
    @State private var statement: StatementFile?
    /// What the data says to total in until Settings is used to say otherwise.
    @State private var inferredCurrency = Self.localeCurrency
    /// Held here only for the Detail screen opened from Upcoming, which is composed here and so
    /// has no feature of its own to have loaded them.
    @State private var rates = RateBook()
    @State private var reload = UUID()
    @State private var tab = Tabs.subscriptions
    @State private var isShowingPro = false
    @State private var isAskingAboutReminders = false
    @State private var isSayingNothingWasNew = false

    private let merchants = BundledCatalog()
    private let reminders = SystemReminders()
    private let purchases = StoreKitPro()
    /// Held here because iOS keeps its notification delegate weakly.
    @State private var taps = ReminderTaps()
    /// The day a tapped reminder was about, so Upcoming opens on it rather than on this month.
    @State private var tappedDay: Date?

    public init() {
        let opened = SubscriptionStore.opened()
        _opened = State(initialValue: opened)
        _isSayingStoreWasReset = State(initialValue: opened.wasReset)
    }

    private var store: SubscriptionStore { opened.store }

    #if DEBUG
        /// SCAFFOLD — delete before shipping, with `ProLockToggle`. Flips the debug answer, so the
        /// locked states can be looked at on a phone instead of only imagined.
        @AppStorage("debugLocksPro") private var debugLocksPro = false
    #endif

    /// The one thing every gated feature reads. A debug build answers yes unless it is told
    /// otherwise: a local StoreKit config only works when Xcode launches the app, so on a phone
    /// there is otherwise nothing to buy with and no way to exercise what the purchase unlocks.
    private var isPro: Bool {
        #if DEBUG
            !debugLocksPro
        #else
            hasEntitlement
        #endif
    }

    private var currency: String { chosenCurrency.isEmpty ? inferredCurrency : chosenCurrency }
    private var language: BadeLanguage { BadeLanguage(rawValue: languageCode) ?? .english }
    private var appearance: BadeAppearance { BadeAppearance(rawValue: appearanceCode) ?? .system }
    private var textSize: BadeTextSize { BadeTextSize(rawValue: textSizeCode) ?? .system }
    private var weekStart: BadeWeekStart { BadeWeekStart(rawValue: weekStartCode) ?? .system }

    /// Reminders are part of Pro, and no lead means nothing is ever scheduled — so this is the one
    /// place the gate is enforced rather than at every call site. What was chosen is kept, and comes
    /// back if Pro is bought.
    private var reminderPreference: ReminderPreference {
        ReminderPreference(
            lead: isPro ? ReminderLead(rawValue: reminderLeadCode) ?? .off : .off,
            timeOfDay: reminderTime)
    }

    /// The cache always answers; the network behind it is what the switch in Settings turns off.
    private var officialRates: any OfficialRateSource {
        CachedOfficialRates(store: store, network: fetchesRates ? NBGRateSource() : nil)
    }

    /// Everything the app is running in. Applied to the root, and to every cover and sheet as well:
    /// presented content is not inside the app's own view tree, so none of this reaches it on its
    /// own. Each of them set the theme and stopped there, which left the whole import flow in
    /// English, on the system's calendar and at the system's text size.
    private var appEnvironment: BadeAppEnvironment {
        BadeAppEnvironment(
            appearance: appearance, language: language, weekStart: weekStart, textSize: textSize)
    }

    public var body: some View {
        root
            .badeAnimation(.badeTransition, value: hasSubscriptions)
            .badeAnimation(.badeTransition, value: isReady)
            .modifier(appEnvironment)
            .task { configureTips() }
            .task(id: reload) { await decideRoot() }
            .task(id: widgetKey) { await publishWidget() }
            // A row deleted in the list, a price edited, a subscription paused: features write to
            // the store directly, so the store is what says something changed.
            .task {
                for await _ in await store.changes() {
                    await publishWidget()
                    await rescheduleFromStore()
                }
            }
            // A purchase made on another device, or an Ask to Buy approved later, arrives here.
            .task { for await e in purchases.entitlementChanges() { hasEntitlement = e } }
            // A tapped reminder opens the calendar on the day it was announcing.
            .task {
                taps.startListening()
                for await day in taps.days {
                    tappedDay = day
                    tab = .upcoming
                }
            }
            .fileImporter(
                isPresented: $isPickingFile,
                allowedContentTypes: [.pdf, .plainText, .commaSeparatedText]
            ) { result in
                guard case .success(let url) = result else { return }
                statement = StatementFile(contentsOf: url)
            }
            .badeCover(item: $statement) { file in
                ImportFlowView(
                    file: file, importer: StatementImporter(), repository: store,
                    rateRepository: store, currency: currency,
                    isCurrencyInferred: chosenCurrency.isEmpty, onOutcome: handleImport
                )
                .modifier(appEnvironment)
            }
            .sheet(isPresented: $isShowingPro) {
                NavigationStack {
                    ProView(
                        model: ProViewModel(purchases: purchases, isEntitled: isPro) { outcome in
                            if outcome == .unlocked { hasEntitlement = true }
                        })
                }
                .modifier(appEnvironment)
            }
            .sheet(isPresented: $isAskingAboutReminders) {
                ReminderPromptView(onOutcome: handleReminderPrompt)
                    .modifier(appEnvironment)
                    .presentationDetents([.medium])
            }
            // Only Welcome opens it from here; once there is a list, the list presents its own.
            .sheet(isPresented: $isAddingManually) {
                SubscriptionFormView(model: manualEntry()).modifier(appEnvironment)
            }
            // Said once, and only when a reset actually happened.
            .alert(Text(.store.resetTitle), isPresented: $isSayingStoreWasReset) {
                Button { } label: { Text(.common.ok) }
            } message: {
                Text(.store.resetMessage)
            }
            .alert(Text(.importing.nothingNewTitle), isPresented: $isSayingNothingWasNew) {
                Button { } label: { Text(.common.ok) }
            } message: {
                Text(.importing.nothingNewMessage)
            }
    }

    /// Welcome is a gate, not a home: it is shown until the first subscription exists and never
    /// returned to. Deciding takes a local read, so nothing is drawn until it is known — a flash
    /// of Welcome on every launch would be worse than a blank moment.
    /// Cross-faded rather than swapped: the way out of the tabs is deleting everything, and a hard
    /// cut from a list of subscriptions to an empty screen reads as a crash.
    @ViewBuilder
    private var root: some View {
        if !isReady {
            LoadingSurface().transition(.opacity)
        } else if hasSubscriptions {
            // Never keyed on `reload`: rebuilding the tabs to refresh them threw away everything
            // the screens had loaded, replayed the hero's arrival count-up, and cross-faded the
            // whole thing. Each tab reloads itself on appearance, which is all that was needed.
            tabs.transition(.opacity)
        } else {
            WelcomeView(language: language, onOutcome: handleWelcome)
            .transition(.opacity)
        }
    }

    /// Import is an action rather than a tab, so it is not here: it lives on Subscriptions.
    /// Subscriptions takes the display currency as a value it watches; Upcoming is still keyed by
    /// it, along with the week start and a tapped day, which do change what it has to compute.
    private var tabs: some View {
        TabView(selection: $tab) {
            Tab(value: Tabs.subscriptions) {
                NavigationStack { subscriptions }
            } label: {
                Label { Text(.subscriptions.title) } icon: { Image(systemName: "repeat") }
            }

            Tab(value: Tabs.upcoming) {
                NavigationStack { upcoming }
                    // A tapped reminder is a navigation, so the screen is rebuilt on its day.
                    .id(currency + weekStartCode + (tappedDay?.description ?? ""))
                    .badeLocked(!isPro) { isShowingPro = true }
            } label: {
                Label { Text(.upcoming.title) } icon: {
                    Image(systemName: isPro ? "calendar" : "calendar.badge.lock")
                }
            }

            Tab(value: Tabs.settings) {
                #if DEBUG
                    NavigationStack { settings.modifier(ProLockToggle(isLocked: $debugLocksPro)) }
                #else
                    NavigationStack { settings }
                #endif
            } label: {
                Label { Text(.settings.title) } icon: { Image(systemName: "gearshape") }
            }
        }
    }

    private var subscriptions: some View {
        SubscriptionsView(
            model: SubscriptionsViewModel(
                currency: currency, repository: store, merchants: merchants,
                officialRates: officialRates,
                rates: { [store] in (try? await store.observedRates()) ?? RateBook() },
                onOutcome: handleSubscriptions),
            currency: currency, isPro: isPro, onUnlock: { isShowingPro = true })
    }

    /// Upcoming may not import Subscriptions, so the destination behind one of its rows is
    /// supplied from here — the one place that knows about both.
    private var upcoming: some View {
        UpcomingView(
            model: UpcomingViewModel(
                currency: currency, calendar: weekStart.calendar, showing: tappedDay,
                repository: store,
                rates: { [store] in (try? await store.observedRates()) ?? RateBook() })
        ) { subscription in
            SubscriptionDetailView(
                model: detail(for: subscription), isPro: isPro,
                onUnlock: { isShowingPro = true })
        }
    }

    private var settings: some View {
        SettingsView(
            model: SettingsViewModel(
                currency: currency, language: language, appearance: appearance,
                textSize: textSize, weekStart: weekStart,
                isCurrencyInferred: chosenCurrency.isEmpty, fetchesRates: fetchesRates,
                isPro: isPro, reminder: reminderPreference, repository: store,
                purchases: purchases,
                isReminderDenied: { [reminders] in await reminders.authorization() == .denied },
                onOutcome: handleSettings),
            isPro: isPro)
    }

    private func detail(for subscription: Subscription) -> SubscriptionDetailViewModel {
        SubscriptionDetailViewModel(
            subscription: subscription, currency: currency, rates: rates, repository: store,
            merchants: merchants, officialRates: officialRates, onOutcome: { _ in })
    }

    /// The one form Welcome can reach. Saving from an empty app is what fills it, so the root
    /// re-decides itself and Welcome gives way to the list.
    private func manualEntry() -> SubscriptionFormViewModel {
        SubscriptionFormViewModel(
            editing: nil, currency: currency, knownCurrencies: [], repository: store,
            merchants: merchants,
            onOutcome: { outcome in
                isAddingManually = false
                if outcome != .cancelled { reload = UUID() }
            })
    }

    /// Pinned to the app's own container, never the App Group. CoreData's default directory became
    /// the group container the moment Bade had one and quietly relocated the SwiftData store; a
    /// framework that picks its own location is exactly the shape of that bug.
    ///
    /// `.immediate` because the two tips live on different screens and can never compete: the
    /// default would hold the second one back for a day for no reason a reader could see.
    private func configureTips() {
        try? Tips.configure([
            .datastoreLocation(.applicationDefault),
            .displayFrequency(.immediate),
        ])
    }

    private func decideRoot() async {
        let stored = (try? await store.all()) ?? []
        hasSubscriptions = !stored.isEmpty
        inferredCurrency = stored.predominantCurrency ?? Self.localeCurrency
        rates = (try? await store.observedRates()) ?? RateBook()
        isReady = true
        hasEntitlement = await purchases.isEntitled()
        await reschedule(for: stored)
    }

    /// The home screen cannot read the store, so it is handed figures instead. Keyed on everything
    /// the snapshot is made of, so a display currency changed in Settings reaches the widget too —
    /// which two hand-placed calls did not.
    private var widgetKey: String { "\(currency)|\(languageCode)|\(isPro)|\(reload)" }

    private func publishWidget() async {
        let stored = (try? await store.all()) ?? []
        let observed = (try? await store.observedRates()) ?? RateBook()
        WidgetFeed()
            .publish(
                WidgetSnapshot(
                    subscriptions: stored, currency: currency, rates: observed, isPro: isPro,
                    localeIdentifier: language.locale.identifier))
    }

    /// Every launch and every change reschedules from scratch: the plan is cheap, and a stale
    /// reminder for a subscription that has been deleted or repriced is worse than none.
    private func reschedule(for stored: [Subscription]) async {
        await reminders.replace(
            with: ReminderPlan.reminders(
                for: stored, preference: reminderPreference, from: .now),
            in: language.locale)
    }

    private func rescheduleFromStore() async {
        let stored = (try? await store.all()) ?? []
        await reschedule(for: stored)
    }

    /// An import that added nothing is not a failure, but it looks like one unless it is said:
    /// everything in the statement was already here. That takes priority over asking about
    /// reminders, which will come round again on the next import.
    private func handleImport(_ outcome: ImportOutcome) {
        statement = nil
        switch outcome {
        case .cancelled: break
        case .chooseAnother: isPickingFile = true
        case .saved(let addedCount):
            reload = UUID()
            // What was just imported is on the list, so that is where an import ends — not on
            // whichever tab happened to be open when the statement was picked.
            tab = .subscriptions
            if addedCount == 0 {
                isSayingNothingWasNew = true
            } else {
                askAboutReminders()
            }
        }
    }

    /// After the total has landed, never before it. Nothing is asked twice, nothing is asked at all
    /// if iOS has already been answered, and nobody is asked for a permission they cannot yet use.
    private func askAboutReminders() {
        guard isPro, !hasAskedAboutReminders else { return }
        Task {
            guard await reminders.authorization() == .notDetermined else { return }
            try? await Task.sleep(for: .seconds(BadeMotion.totalReveal))
            hasAskedAboutReminders = true
            isAskingAboutReminders = true
        }
    }

    /// A yes here is what earns the system prompt. A no from iOS needs no handling: Settings reads
    /// the answer for itself, and a lead with no permission behind it schedules nothing.
    private func handleReminderPrompt(_ outcome: ReminderPromptOutcome) {
        isAskingAboutReminders = false
        guard outcome == .turnOn else { return }
        Task {
            guard await reminders.requestAuthorization() else { return }
            reminderLeadCode = ReminderLead.oneDay.rawValue
            await rescheduleFromStore()
        }
    }

    private func handleSubscriptions(_ outcome: SubscriptionsOutcome) {
        switch outcome {
        case .importStatement: isPickingFile = true
        case .dataCleared: clearedEverything()
        }
    }

    /// Welcome carries the language switch because Settings cannot be reached until something is
    /// imported, and the reader who most needs Georgian is the one who has not started yet.
    private func handleWelcome(_ outcome: WelcomeOutcome) {
        switch outcome {
        case .importStatement: isPickingFile = true
        case .addManually: isAddingManually = true
        case .languageChanged(let language): languageCode = language.rawValue
        }
    }

    private func handleSettings(_ outcome: SettingsOutcome) {
        switch outcome {
        case .currencyChanged(let code): chosenCurrency = code
        case .languageChanged(let language): languageCode = language.rawValue
        case .appearanceChanged(let appearance): appearanceCode = appearance.rawValue
        case .textSizeChanged(let size): textSizeCode = size.rawValue
        case .weekStartChanged(let start): weekStartCode = start.rawValue
        case .rateFetchingChanged(let fetches): fetchesRates = fetches
        case .reminderLeadChanged(let lead):
            reminderLeadCode = lead.rawValue
            Task {
                // Turning them on here has to be able to ask iOS too: the prompt after the first
                // import may have been declined, or never reached at all.
                if lead.isOn { _ = await reminders.requestAuthorization() }
                await rescheduleFromStore()
            }
        case .reminderTimeChanged(let minutes):
            reminderTime = minutes
            Task { await rescheduleFromStore() }
        // Rescheduled either way: a lead that was gated takes effect now, and a revoked
        // entitlement resolves the lead to `.off`, which clears what iOS is still holding.
        case .proChanged(let isEntitled):
            hasEntitlement = isEntitled
            Task { await rescheduleFromStore() }
        case .dataCleared: clearedEverything()
        }
    }

    /// The list is already emptying and the total is already counting down to nothing. Welcome
    /// waits for it: cutting to an empty screen mid-count is what made deleting everything feel
    /// like something had gone wrong rather than like something had been done.
    private func clearedEverything() {
        Task {
            try? await Task.sleep(for: .seconds(BadeMotion.totalReveal))
            reload = UUID()
        }
    }

    /// Only reached before any statement has been read; after that the data decides.
    private static var localeCurrency: String {
        Locale.current.currency?.identifier.uppercased() ?? "USD"
    }

}

/// `dynamicTypeSize` has no "leave it alone" value, so `system` reads what it inherited and hands
/// it straight back. Branching instead would change the view's shape, and changing shape above a
/// `TabView` tears it down and drops you back on the first tab.
private struct TextSizeOverride: ViewModifier {
    @Environment(\.dynamicTypeSize) private var inherited

    let size: BadeTextSize

    func body(content: Content) -> some View {
        content.environment(\.dynamicTypeSize, size.dynamicTypeSize ?? inherited)
    }
}

/// The first frame the app draws, held while a local read decides between Welcome and the tabs.
/// The net weaves itself across the whole screen under the name — `badeNet` was written for this
/// and had never once been used — so opening Bade begins with Bade rather than with a blank screen.
/// The system's own launch image is generated and can show nothing, so this is the only chance.
private struct LoadingSurface: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var strength: Double = 0

    var body: some View {
        Text(.app.name)
            .font(.badeTotal(size: BadeTypography.wordmarkSize))
            .foregroundStyle(theme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                NetBackground(
                    strength: strength, peakOpacity: NetMetrics.launchOpacity,
                    reachFactor: NetMetrics.launchReach
                )
                .ignoresSafeArea()
            )
            .background(theme.surface, ignoresSafeAreaEdges: .all)
            .task {
                withBadeAnimation(.badeNet, reduceMotion: reduceMotion) { strength = 1 }
            }
    }
}

#if DEBUG
    /// SCAFFOLD — delete before shipping, with `debugLocksPro`. A debug build cannot buy anything,
    /// so it answers yes to Pro and every locked state is invisible. This flips that answer from
    /// the Settings tab, which is the one place all of them can be reached from.
    private struct ProLockToggle: ViewModifier {
        @Binding var isLocked: Bool

        func body(content: Content) -> some View {
            content.toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isLocked.toggle() } label: {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    }
                    .accessibilityLabel(Text(verbatim: isLocked ? "Unlock Pro" : "Lock Pro"))
                }
            }
        }
    }
#endif

/// The app's appearance, palette, language, week start and text size, in one piece so the root and
/// everything it presents cannot drift apart.
private struct BadeAppEnvironment: ViewModifier {
    let appearance: BadeAppearance
    let language: BadeLanguage
    let weekStart: BadeWeekStart
    let textSize: BadeTextSize

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(appearance.colorScheme)
            .badeTheme()
            .environment(\.locale, language.locale)
            .environment(\.calendar, weekStart.calendar)
            .modifier(TextSizeOverride(size: textSize))
    }
}
