#if DEBUG
    import Core
    import DesignSystem
    import Foundation
    import SwiftUI

    /// Explicitly typed throughout: previews rewrite every literal into `__designTimeString(...)`,
    /// and inferring types through that defeats the compiler.
    private func stub(
        _ merchant: String, _ amount: String, _ currency: String, _ cadence: Cadence,
        _ nextChargeInDays: Int
    ) -> Subscription {
        let now: Date = Date(timeIntervalSince1970: 1_756_000_000)
        return Subscription(
            merchant: merchant,
            amount: Decimal(string: amount) ?? 0,
            currency: currency,
            cadence: cadence,
            firstChargeDate: now.addingTimeInterval(-15_552_000),
            lastChargeDate: now,
            nextChargeDate: now.addingTimeInterval(Double(nextChargeInDays) * 86_400),
            confidence: .confident)
    }

    private struct StubRepository: SubscriptionRepository {
        let subscriptions: [Subscription]
        func all() async throws -> [Subscription] { subscriptions }
        func save(_ subscription: Subscription) async throws {}
        func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
        func delete(id: UUID) async throws {}
        func deleteAll() async throws {}
    }

    private func stubRates() -> RateBook {
        let observed: Date = Date(timeIntervalSince1970: 1_756_000_000)
        var rates: RateBook = RateBook()
        rates.record(ObservedRate(date: observed, from: "USD", to: "GEL", rate: 2.72))
        rates.record(ObservedRate(date: observed, from: "EUR", to: "GEL", rate: 2.95))
        return rates
    }

    @MainActor
    private func stubSubscriptions() -> some View {
        let stored: [Subscription] = [
            stub("ChatGPT Plus", "20.00", "USD", .monthly, 5),
            stub("YouTube Premium", "42.90", "GEL", .monthly, 8),
            stub("Netflix", "12.99", "USD", .monthly, 5),
            stub("Adobe Creative Cloud", "19.99", "USD", .monthly, 12),
            stub("Epidemic Sound", "8.99", "EUR", .monthly, 19),
            stub("MAGTICOM", "35.00", "GEL", .monthly, 2),
            stub("Google One", "50.00", "GEL", .annual, 40),
        ]
        let rates: RateBook = stubRates()
        let model = SubscriptionsViewModel(
            currency: "GEL", repository: StubRepository(subscriptions: stored),
            rates: { rates }, onOutcome: { _ in })
        return NavigationStack {
            SubscriptionsView(model: model, currency: "GEL", isPro: true, onUnlock: {})
        }
    }

    #Preview("Subscriptions") { stubSubscriptions().badeTheme() }

    #Preview("Subscriptions · Dark") {
        stubSubscriptions().badeTheme().preferredColorScheme(.dark)
    }

    #Preview("Subscriptions · ქართული") {
        stubSubscriptions().badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Subscriptions · Large text") {
        stubSubscriptions().badeTheme().environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
