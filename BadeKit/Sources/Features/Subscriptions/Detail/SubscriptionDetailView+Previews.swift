#if DEBUG
    import Core
    import DesignSystem
    import Foundation
    import SwiftUI

    /// Explicitly typed throughout: previews rewrite every literal into `__designTimeString(...)`,
    /// and inferring types through that defeats the compiler.
    private func stubCharges(_ months: Int, _ amount: String, _ currency: String) -> [Charge] {
        let value: Decimal = Decimal(string: amount) ?? 0
        let end: Date = Date(timeIntervalSince1970: 1_756_000_000)
        let conversion = CurrencyConversion(
            from: currency, to: "GEL", bankRate: Decimal(string: "2.72")!,
            schemeRate: Decimal(string: "2.61")!)
        return (0..<months).map { index in
            Charge(
                date: end.addingTimeInterval(-Double(index) * 2_592_000),
                amount: index > 5 ? value - 3 : value, currency: currency,
                conversion: currency == "GEL" ? nil : conversion)
        }
    }

    private struct StubRepository: SubscriptionRepository {
        func all() async throws -> [Subscription] { [] }
        func save(_ subscription: Subscription) async throws {}
        func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
        func delete(id: UUID) async throws {}
        func deleteAll() async throws {}
    }

    @MainActor
    private func stubDetail(currency: String, months: Int) -> some View {
        let end: Date = Date(timeIntervalSince1970: 1_756_000_000)
        let charges: [Charge] = stubCharges(months, "12.99", currency)
        let subscription = Subscription(
            merchant: "Netflix",
            amount: Decimal(string: "12.99")!,
            currency: currency,
            cadence: .monthly,
            firstChargeDate: charges.map(\.date).min() ?? end,
            lastChargeDate: end,
            nextChargeDate: end.addingTimeInterval(2_592_000),
            charges: charges,
            priceChanges: [
                PriceChange(
                    date: end.addingTimeInterval(-5 * 2_592_000),
                    from: Decimal(string: "9.99")!, to: Decimal(string: "12.99")!)
            ],
            confidence: .confident)

        var rates: RateBook = RateBook()
        rates.record(ObservedRate(date: end, from: "USD", to: "GEL", rate: 2.72))

        let model = SubscriptionDetailViewModel(
            subscription: subscription, currency: "GEL", rates: rates,
            repository: StubRepository(), onOutcome: { _ in })
        return NavigationStack { SubscriptionDetailView(model: model) }
    }

    #Preview("Detail · foreign") { stubDetail(currency: "USD", months: 12).badeTheme() }

    #Preview("Detail · Dark") {
        stubDetail(currency: "USD", months: 12).badeTheme().preferredColorScheme(.dark)
    }

    #Preview("Detail · local, short history") {
        stubDetail(currency: "GEL", months: 4).badeTheme()
    }

    #Preview("Detail · ქართული") {
        stubDetail(currency: "USD", months: 12).badeTheme()
            .environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Detail · Large text") {
        stubDetail(currency: "USD", months: 12).badeTheme()
            .environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
