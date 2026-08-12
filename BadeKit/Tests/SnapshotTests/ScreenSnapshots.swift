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

    /// §11 asks for snapshots in both languages, both appearances and at accessibility sizes.
    /// These render on the simulator and write PNGs for a person to look at; they assert only that
    /// a screen renders at all, because a machine cannot tell a good layout from a bad one.
    ///
    /// UIKit appears here and nowhere else — hosting a view in a real window is the only way to
    /// capture the navigation bar along with it. `Sources/` stays free of it.
    @MainActor
    @Suite("Screen snapshots")
    struct ScreenSnapshots {
        @Test func everyScreenInEveryVariant() async throws {
            for variant in Variant.all {
                try await capture("form-new", variant) { form(editing: nil) }
                try await capture("form-editing", variant) { form(editing: netflix()) }
                try await capture("upcoming", variant) { await upcoming(stored()) }
                try await capture("settings", variant) { await settings(stored()) }
                try await capture("subscriptions", variant) { await subscriptions(stored()) }
            }
            try await capture("upcoming-empty", .light) { await upcoming([]) }
            try await capture("settings-empty", .light) { await settings([]) }

            print("BADE_SNAPSHOT_DIR=\(Self.directory.path)")
        }
    }

    /// The axes worth looking at, each a whole screenshot rather than a difference.
    struct Variant {
        let name: String
        let scheme: UIUserInterfaceStyle
        let locale: Locale
        let size: DynamicTypeSize

        static let light = Variant(name: "light", scheme: .light, locale: en, size: .large)
        static let dark = Variant(name: "dark", scheme: .dark, locale: en, size: .large)
        static let georgian = Variant(name: "ka", scheme: .light, locale: ka, size: .large)
        static let large = Variant(
            name: "large-text", scheme: .light, locale: en, size: .accessibility2)

        static let all = [light, dark, georgian, large]
        private static let en = Locale(identifier: "en")
        private static let ka = Locale(identifier: "ka")
    }

    extension ScreenSnapshots {
        static let directory: URL = {
            let url = URL(filePath: NSTemporaryDirectory()).appending(path: "bade-snapshots")
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }()

        private static let size = CGSize(width: 402, height: 874)

        func capture(
            _ name: String, _ variant: Variant, of view: () async -> some View
        ) async throws {
            let content = await view()
            let root =
                content
                .badeTheme()
                .environment(\.locale, variant.locale)
                .environment(\.dynamicTypeSize, variant.size)

            let controller = UIHostingController(rootView: root)
            controller.overrideUserInterfaceStyle = variant.scheme
            controller.view.frame = CGRect(origin: .zero, size: Self.size)

            let window = UIWindow(frame: controller.view.frame)
            window.overrideUserInterfaceStyle = variant.scheme
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.layoutIfNeeded()
            // A list lays its rows out on a later turn of the run loop, not on layout. Awaiting
            // hands the main thread back so that turn actually happens.
            try await Task.sleep(for: .milliseconds(400))
            controller.view.layoutIfNeeded()

            // `drawHierarchy` renders nothing for a window that was never on screen; the layer
            // tree can be asked directly.
            let image = UIGraphicsImageRenderer(size: Self.size).image { context in
                window.layer.render(in: context.cgContext)
            }
            let data = try #require(image.pngData())
            try data.write(to: Self.directory.appending(path: "\(name)-\(variant.name).png"))
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
                currency: "GEL", repository: StubRepository(subscriptions: subscriptions),
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

        return NavigationStack { SettingsView(model: model) }
    }

    @MainActor
    private func subscriptions(_ subscriptions: [Subscription]) async -> some View {
        let book = rates()
        let model = await primed(
            SubscriptionsViewModel(
                currency: "GEL", repository: StubRepository(subscriptions: subscriptions),
                merchants: StubMerchants(), rates: { book }, onOutcome: { _ in })
        ) { $0.send(.appeared) }

        return NavigationStack { SubscriptionsView(model: model) }
    }
#endif
