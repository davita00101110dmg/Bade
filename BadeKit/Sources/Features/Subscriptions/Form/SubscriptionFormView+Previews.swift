#if DEBUG
    import Core
    import DesignSystem
    import Foundation
    import SwiftUI

    /// Explicitly typed throughout: previews rewrite every literal into `__designTimeString(...)`,
    /// and inferring types through that defeats the compiler.
    private struct StubRepository: SubscriptionRepository {
        func all() async throws -> [Subscription] { [] }
        func save(_ subscription: Subscription) async throws {}
        func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
        func delete(id: UUID) async throws {}
        func deleteAll() async throws {}
    }

    private struct StubMerchants: MerchantSuggesting {
        func suggestedMerchants(matching text: String) -> [String] {
            ["Netflix", "Nebula", "NordVPN"]
        }
    }

    private func stub() -> Subscription {
        let now: Date = Date(timeIntervalSince1970: 1_756_000_000)
        return Subscription(
            merchant: "Netflix",
            amount: Decimal(string: "12.99") ?? 0,
            currency: "USD",
            cadence: .monthly,
            firstChargeDate: now.addingTimeInterval(-15_552_000),
            lastChargeDate: now,
            nextChargeDate: now.addingTimeInterval(864_000),
            confidence: .confident)
    }

    @MainActor
    private func stubForm(editing subscription: Subscription?) -> some View {
        let model = SubscriptionFormViewModel(
            editing: subscription, currency: "GEL", knownCurrencies: ["GEL", "USD"],
            repository: StubRepository(), merchants: StubMerchants(), onOutcome: { _ in })
        return SubscriptionFormView(model: model)
    }

    #Preview("Form · New") { stubForm(editing: nil).badeTheme() }

    #Preview("Form · Editing") { stubForm(editing: stub()).badeTheme() }

    #Preview("Form · Dark") {
        stubForm(editing: stub()).badeTheme().preferredColorScheme(.dark)
    }

    #Preview("Form · ქართული") {
        stubForm(editing: stub()).badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Form · Large text") {
        stubForm(editing: stub()).badeTheme().environment(\.dynamicTypeSize, .accessibility2)
    }

    #Preview("Currency picker") {
        NavigationStack {
            CurrencyPicker(known: ["GEL", "USD"], selected: "USD", onPick: { _ in })
        }
        .badeTheme()
    }
#endif
