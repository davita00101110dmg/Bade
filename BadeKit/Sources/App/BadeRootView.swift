import Core
import DesignSystem
import Import
import Persistence
import Pipeline
import Subscriptions
import SwiftUI
import UniformTypeIdentifiers
import Welcome

public struct BadeRootView: View {
    /// TODO: Settings (§10) will own this. GEL is the launch default until that screen exists.
    private static let displayCurrency = "GEL"

    @State private var store = Self.makeStore()
    @State private var hasSubscriptions = false
    @State private var isReady = false
    @State private var isPickingFile = false
    @State private var statement: StatementFile?
    @State private var reload = UUID()

    public init() {}

    public var body: some View {
        root
            .badeTheme()
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
                    rateRepository: store, currency: Self.displayCurrency, onOutcome: handleImport
                )
                .badeTheme()
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
            NavigationStack {
                SubscriptionsView(
                    model: SubscriptionsViewModel(
                        currency: Self.displayCurrency, repository: store,
                        rates: { [store] in (try? await store.observedRates()) ?? RateBook() },
                        onOutcome: handleSubscriptions)
                )
            }
            .id(reload)
        } else {
            WelcomeView(onImport: { isPickingFile = true }, onAddManually: {})
        }
    }

    private func decideRoot() async {
        hasSubscriptions = !((try? await store.all()) ?? []).isEmpty
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

    /// A local store that cannot open is unrecoverable — there is no degraded mode to fall back to.
    private static func makeStore() -> SubscriptionStore {
        SubscriptionStore(modelContainer: try! SubscriptionStore.container())
    }
}

private struct LoadingSurface: View {
    @Environment(\.badeTheme) private var theme

    var body: some View { theme.surface.ignoresSafeArea() }
}
