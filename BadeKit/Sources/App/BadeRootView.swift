import Catalog
import Core
import DesignSystem
import FX
import Import
import Localization
import Persistence
import Pipeline
import Settings
import Subscriptions
import SwiftUI
import UniformTypeIdentifiers
import Upcoming
import Welcome

public struct BadeRootView: View {
    private enum Tabs: Hashable { case subscriptions, upcoming, settings }

    @AppStorage("displayCurrency") private var chosenCurrency = ""
    @AppStorage("language") private var languageCode = BadeLanguage.matchingDevice.rawValue
    @AppStorage("appearance") private var appearanceCode = BadeAppearance.system.rawValue
    @AppStorage("textSize") private var textSizeCode = BadeTextSize.system.rawValue
    @AppStorage("weekStart") private var weekStartCode = BadeWeekStart.system.rawValue
    @AppStorage("fetchesRates") private var fetchesRates = true
    /// Stands in for a purchase until StoreKit exists (step 13). Everything gated reads this and
    /// nothing else, so the day it becomes an entitlement only this line changes.
    @AppStorage("isPro") private var isPro = false

    @State private var store = Self.makeStore()
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

    private let merchants = BundledCatalog()

    public init() {}

    private var currency: String { chosenCurrency.isEmpty ? inferredCurrency : chosenCurrency }
    private var language: BadeLanguage { BadeLanguage(rawValue: languageCode) ?? .english }
    private var appearance: BadeAppearance { BadeAppearance(rawValue: appearanceCode) ?? .system }
    private var textSize: BadeTextSize { BadeTextSize(rawValue: textSizeCode) ?? .system }
    private var weekStart: BadeWeekStart { BadeWeekStart(rawValue: weekStartCode) ?? .system }

    /// The cache always answers; the network behind it is what the switch in Settings turns off.
    private var officialRates: any OfficialRateSource {
        CachedOfficialRates(store: store, network: fetchesRates ? NBGRateSource() : nil)
    }

    public var body: some View {
        root
            .preferredColorScheme(appearance.colorScheme)
            .badeTheme()
            .environment(\.locale, language.locale)
            .environment(\.calendar, weekStart.calendar)
            .modifier(TextSizeOverride(size: textSize))
            .task(id: reload) { await decideRoot() }
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
                    rateRepository: store, currency: currency, onOutcome: handleImport
                )
                .badeTheme()
            }
            .sheet(isPresented: $isShowingPro) {
                NavigationStack { ProView() }.badeTheme()
            }
            // Only Welcome opens it from here; once there is a list, the list presents its own.
            .sheet(isPresented: $isAddingManually) {
                SubscriptionFormView(model: manualEntry()).badeTheme()
            }
    }

    /// Welcome is a gate, not a home: it is shown until the first subscription exists and never
    /// returned to. Deciding takes a local read, so nothing is drawn until it is known — a flash
    /// of Welcome on every launch would be worse than a blank moment.
    @ViewBuilder
    private var root: some View {
        if !isReady {
            LoadingSurface()
        } else if hasSubscriptions {
            tabs.id(reload)
        } else {
            WelcomeView(
                onImport: { isPickingFile = true }, onAddManually: { isAddingManually = true })
        }
    }

    /// Import is an action rather than a tab, so it is not here: it lives on Subscriptions.
    /// The two data tabs are keyed by the display currency, so changing it in Settings rebuilds
    /// them without throwing the user out of the screen they changed it on.
    private var tabs: some View {
        TabView(selection: $tab) {
            Tab(value: Tabs.subscriptions) {
                NavigationStack { subscriptions }.id(currency)
            } label: {
                Label { Text(.subscriptions.title) } icon: { Image(systemName: "repeat") }
            }

            Tab(value: Tabs.upcoming) {
                NavigationStack { upcoming }
                    .id(currency + weekStartCode)
                    .badeLocked(!isPro) { isShowingPro = true }
            } label: {
                Label { Text(.upcoming.title) } icon: {
                    Image(systemName: isPro ? "calendar" : "calendar.badge.lock")
                }
            }

            Tab(value: Tabs.settings) {
                NavigationStack { settings }
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
                onOutcome: handleSubscriptions))
    }

    /// Upcoming may not import Subscriptions, so the destination behind one of its rows is
    /// supplied from here — the one place that knows about both.
    private var upcoming: some View {
        UpcomingView(
            model: UpcomingViewModel(
                currency: currency, calendar: weekStart.calendar, repository: store,
                rates: { [store] in (try? await store.observedRates()) ?? RateBook() })
        ) { subscription in
            SubscriptionDetailView(model: detail(for: subscription))
        }
    }

    private var settings: some View {
        SettingsView(
            model: SettingsViewModel(
                currency: currency, language: language, appearance: appearance,
                textSize: textSize, weekStart: weekStart,
                isCurrencyInferred: chosenCurrency.isEmpty, fetchesRates: fetchesRates,
                repository: store, onOutcome: handleSettings))
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

    private func decideRoot() async {
        let stored = (try? await store.all()) ?? []
        hasSubscriptions = !stored.isEmpty
        inferredCurrency = stored.predominantCurrency ?? Self.localeCurrency
        rates = (try? await store.observedRates()) ?? RateBook()
        isReady = true
    }

    private func handleImport(_ outcome: ImportOutcome) {
        statement = nil
        switch outcome {
        case .cancelled, .foundNothing: break
        case .chooseAnother: isPickingFile = true
        case .saved: reload = UUID()
        }
    }

    private func handleSubscriptions(_ outcome: SubscriptionsOutcome) {
        switch outcome {
        case .importStatement: isPickingFile = true
        case .dataCleared: reload = UUID()
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
        case .dataCleared: reload = UUID()
        }
    }

    /// Only reached before any statement has been read; after that the data decides.
    private static var localeCurrency: String {
        Locale.current.currency?.identifier.uppercased() ?? "USD"
    }

    /// A local store that cannot open is unrecoverable — there is no degraded mode to fall back to.
    private static func makeStore() -> SubscriptionStore {
        SubscriptionStore(modelContainer: try! SubscriptionStore.container())
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

private struct LoadingSurface: View {
    @Environment(\.badeTheme) private var theme

    var body: some View { theme.surface.ignoresSafeArea() }
}
