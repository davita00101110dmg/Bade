#if DEBUG
    import Core
    import DesignSystem
    import Foundation
    import Localization
    import SwiftUI

    /// Explicitly typed throughout: previews rewrite every literal into `__designTimeString(...)`,
    /// and inferring types through that defeats the compiler.
    private func stub(_ merchant: String, _ amount: String, _ currency: String) -> Subscription {
        let now: Date = Date(timeIntervalSince1970: 1_756_000_000)
        return Subscription(
            merchant: merchant,
            amount: Decimal(string: amount) ?? 0,
            currency: currency,
            cadence: .monthly,
            firstChargeDate: now.addingTimeInterval(-15_552_000),
            lastChargeDate: now,
            nextChargeDate: now.addingTimeInterval(864_000),
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

    @MainActor
    private func stubSettings(_ stored: [Subscription]) -> some View {
        let model = SettingsViewModel(
            currency: "GEL", language: .english, repository: StubRepository(subscriptions: stored),
            onOutcome: { _ in })
        return NavigationStack { SettingsView(model: model) }
    }

    @MainActor
    private func stubFull() -> some View {
        stubSettings([stub("Netflix", "12.99", "USD"), stub("MAGTICOM", "35.00", "GEL")])
    }

    #Preview("Settings") { stubFull().badeTheme() }

    #Preview("Settings · Dark") { stubFull().badeTheme().preferredColorScheme(.dark) }

    #Preview("Settings · ქართული") {
        stubFull().badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Settings · Large text") {
        stubFull().badeTheme().environment(\.dynamicTypeSize, .accessibility2)
    }

    #Preview("Settings · Nothing stored") { stubSettings([]).badeTheme() }
#endif
