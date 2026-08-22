#if os(iOS)
    import Core
    import DesignSystem
    import Foundation
    import Localization
    import Settings
    import Subscriptions
    import SwiftUI
    import Testing
    import UIKit
    import Upcoming
    import Welcome

    /// §11 asks for snapshots in both languages, both appearances and at accessibility sizes.
    ///
    /// These used to render PNGs into a temporary folder and assert only that a screen rendered at
    /// all — a screenshot generator rather than a test, so a layout could break without anything
    /// failing. Each render is now compared against a reference committed to the repository.
    ///
    /// They also stopped compiling at some point and nobody noticed, because `#if os(iOS)` means
    /// `swift test` on the host never builds this file. That is the standing risk here: these are
    /// invisible unless somebody runs them on a simulator, which is why the command is written down
    /// in NEXT-SESSION.md rather than remembered.
    ///
    /// UIKit appears here and nowhere else — hosting a view in a real window is the only way to
    /// capture the navigation bar along with it. `Sources/` stays free of it.
    @MainActor
    @Suite("Screen snapshots")
    struct ScreenSnapshots {
        @Test func everyScreenInEveryVariant() async throws {
            for variant in Variant.all {
                try await capture("welcome", variant) { welcome() }
                try await capture("form-new", variant) { form(editing: nil) }
                try await capture("form-editing", variant) { form(editing: netflix()) }
                try await capture("upcoming", variant) { await upcoming(stored()) }
                try await capture("upcoming-locked", variant) {
                    await upcoming(stored()).badeLocked(true) {}
                }
                try await capture("settings", variant) { await settings(stored()) }
                try await capture("subscriptions", variant) { await subscriptions(stored()) }
                try await capture("detail", variant) { detail(netflix()) }
                try await capture("pro", variant) { pro(isEntitled: false) }
                try await capture("pro-owned", variant) { pro(isEntitled: true) }
            }
            try await capture("upcoming-empty", .light) { await upcoming([]) }
            try await capture("settings-empty", .light) { await settings([]) }
        }
    }

    /// The axes worth looking at, each a whole screenshot rather than a difference.
    struct Variant {
        let name: String
        let scheme: UIUserInterfaceStyle
        let locale: Locale
        let size: DynamicTypeSize
        /// Increase Contrast. `ColorSchemeContrast` is read-only in the environment, so the trait
        /// has to be overridden on the host — which is also the honest test, since it proves the
        /// real system signal reaches the palette rather than that a value was injected.
        var contrast: UIAccessibilityContrast = .normal

        static let light = Variant(name: "light", scheme: .light, locale: en, size: .large)
        static let dark = Variant(name: "dark", scheme: .dark, locale: en, size: .large)
        static let georgian = Variant(name: "ka", scheme: .light, locale: ka, size: .large)
        static let large = Variant(
            name: "large-text", scheme: .light, locale: en, size: .accessibility2)
        static let increasedContrast = Variant(
            name: "increased-contrast", scheme: .light, locale: en, size: .large, contrast: .high)

        static let all = [light, dark, georgian, large, increasedContrast]
        private static let en = Locale(identifier: "en")
        private static let ka = Locale(identifier: "ka")
    }

    extension ScreenSnapshots {
        private static let size = CGSize(width: 402, height: 874)

        func capture(
            _ name: String, _ variant: Variant, of view: () async -> some View
        ) async throws {
            let content = await view()
            // Animations off, or the screen is unrepeatable. The hero total counts up over
            // `BadeMotion.totalReveal` and the net fades in from nothing, so a capture taken
            // mid-flight differed from the previous one by up to 5% of its pixels — measured, with
            // no code change between runs. That noise was larger than most real regressions, which
            // made the comparison worse than useless: it failed at random and caught nothing.
            //
            // `accessibilityReduceMotion` would have been the app's own switch for this, but it is
            // read-only in the environment. Suppressing the transaction reaches the same screens.
            let root =
                content
                .badeTheme()
                .environment(\.locale, variant.locale)
                .environment(\.dynamicTypeSize, variant.size)
                .transaction { $0.disablesAnimations = true }

            let controller = UIHostingController(rootView: root)
            controller.overrideUserInterfaceStyle = variant.scheme
            controller.traitOverrides.accessibilityContrast = variant.contrast
            controller.view.frame = CGRect(origin: .zero, size: Self.size)

            let window = UIWindow(frame: controller.view.frame)
            window.overrideUserInterfaceStyle = variant.scheme
            window.traitOverrides.accessibilityContrast = variant.contrast
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.layoutIfNeeded()
            // A list lays its rows out on a later turn of the run loop, not on layout. Awaiting
            // hands the main thread back so that turn actually happens — and long enough that
            // anything Reduce Motion did not settle has finished.
            try await Task.sleep(for: .milliseconds(2200))
            controller.view.layoutIfNeeded()

            // `drawHierarchy` renders nothing for a window that was never on screen; the layer
            // tree can be asked directly.
            //
            // Scale 1 rather than the simulator's native scale: a reference at 3x is three times
            // the pixels and three times the file, and no layout regression needs that resolution
            // to be visible.
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: Self.size, format: format).image { context in
                window.layer.render(in: context.cgContext)
            }
            try SnapshotComparison.verify(image, named: "\(name)-\(variant.name)")
        }
    }

    // MARK: - What the screens are shown with

    private struct StubRepository: SubscriptionRepository {
        let subscriptions: [Subscription]
        func all() async throws -> [Subscription] { subscriptions }
        func save(_ subscription: Subscription) async throws {}
        func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
        func delete(id: UUID) async throws {}
        func deleteAll() async throws {}
    }

    private struct StubMerchants: MerchantSuggesting {
        func suggestedMerchants(matching text: String) -> [String] { [] }
    }

    private func date(_ offsetDays: Int) -> Date {
        Date(timeIntervalSince1970: 1_786_000_000).addingTimeInterval(Double(offsetDays) * 86_400)
    }

    private func stub(
        _ merchant: String, _ amount: String, _ currency: String, _ cadence: Cadence, _ next: Int
    ) -> Subscription {
        Subscription(
            merchant: merchant, amount: Decimal(string: amount) ?? 0, currency: currency,
            cadence: cadence, firstChargeDate: date(-180), lastChargeDate: date(-2),
            nextChargeDate: date(next), confidence: .confident)
    }

    private func netflix() -> Subscription { stub("Netflix", "12.99", "USD", .monthly, 5) }

    private func stored() -> [Subscription] {
        [
            netflix(),
            stub("ChatGPT Plus", "20.00", "USD", .monthly, 3),
            stub("YouTube Premium", "42.90", "GEL", .monthly, 8),
            stub("Adobe Creative Cloud", "19.99", "USD", .monthly, 12),
            stub("Epidemic Sound", "8.99", "EUR", .monthly, 19),
            stub("MAGTICOM", "35.00", "GEL", .monthly, 1),
            stub("Google One", "50.00", "GEL", .annual, 40),
        ]
    }

    private func rates() -> RateBook {
        var book = RateBook()
        book.record(ObservedRate(date: date(-2), from: "USD", to: "GEL", rate: 2.72))
        book.record(ObservedRate(date: date(-2), from: "EUR", to: "GEL", rate: 2.95))
        return book
    }

    @MainActor
    private func form(editing subscription: Subscription?) -> some View {
        SubscriptionFormView(
            model: SubscriptionFormViewModel(
                editing: subscription, currency: "GEL", knownCurrencies: ["GEL", "USD"],
                today: date(0),
                repository: StubRepository(subscriptions: []), merchants: StubMerchants(),
                onOutcome: { _ in }))
    }

    /// A window with no scene never runs SwiftUI's appearance lifecycle, so `onAppear` — and the
    /// load it starts — has to be driven by hand before anything is rendered.
    @MainActor
    private func primed<Model>(_ model: Model, _ load: (Model) -> Void) async -> Model {
        load(model)
        try? await Task.sleep(for: .milliseconds(200))
        return model
    }

    @MainActor
    private func upcoming(_ subscriptions: [Subscription]) async -> some View {
        let book = rates()
        let model = await primed(
            UpcomingViewModel(
                currency: "GEL", today: date(0),
                repository: StubRepository(subscriptions: subscriptions),
                rates: { book })
        ) { $0.send(.appeared) }

        return NavigationStack {
            UpcomingView(model: model) { subscription in
                Text(verbatim: subscription.merchant)
            }
        }
    }

    @MainActor
    private func settings(_ subscriptions: [Subscription]) async -> some View {
        let model = await primed(
            SettingsViewModel(
                currency: "GEL", language: .english,
                repository: StubRepository(subscriptions: subscriptions), onOutcome: { _ in })
        ) { $0.send(.appeared) }

        return NavigationStack { SettingsView(model: model, isPro: true) }
    }

    @MainActor
    private func welcome() -> some View {
        WelcomeView(language: .english) { _ in }
    }

    @MainActor
    private func pro(isEntitled: Bool) -> some View {
        NavigationStack { ProView(model: ProViewModel(isEntitled: isEntitled)) }
    }

    @MainActor
    private func detail(_ subscription: Subscription) -> some View {
        NavigationStack {
            SubscriptionDetailView(
                model: SubscriptionDetailViewModel(
                    subscription: subscription, currency: "GEL", rates: rates(),
                    repository: StubRepository(subscriptions: []), merchants: StubMerchants(),
                    onOutcome: { _ in }),
                isPro: true, onUnlock: {})
        }
    }

    @MainActor
    private func subscriptions(_ subscriptions: [Subscription]) async -> some View {
        let book = rates()
        let model = await primed(
            SubscriptionsViewModel(
                currency: "GEL", repository: StubRepository(subscriptions: subscriptions),
                merchants: StubMerchants(), rates: { book }, onOutcome: { _ in })
        ) { $0.send(.appeared) }

        return NavigationStack {
            SubscriptionsView(model: model, currency: "GEL", isPro: true, onUnlock: {})
        }
    }
#endif
