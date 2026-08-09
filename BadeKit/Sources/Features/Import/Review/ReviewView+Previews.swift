#if DEBUG
    import Core
    import DesignSystem
    import Foundation
    import SwiftUI

    /// Explicitly typed throughout: previews rewrite every literal into `__designTimeString(...)`,
    /// and inferring types through that defeats the compiler.
    private func stubCharges(_ count: Int, _ amount: Decimal, _ currency: String)
        -> [RawTransaction]
    {
        let start: Date = Date(timeIntervalSince1970: 1_710_000_000)
        return (0..<count).map { index in
            RawTransaction(
                date: start.addingTimeInterval(Double(index) * 2_592_000),
                rawDescription: "stub", amount: amount, currency: currency, sourceLine: "stub")
        }
    }

    private func stubDetection(
        _ merchant: String, _ amount: String, _ currency: String, _ confidence: Confidence,
        _ charges: Int, priceRose: Bool = false
    ) -> DetectedSubscription {
        let value: Decimal = Decimal(string: amount) ?? 0
        let changes: [PriceChange] =
            priceRose
            ? [
                PriceChange(
                    date: Date(timeIntervalSince1970: 1_715_000_000), from: value - 4, to: value)
            ] : []
        return DetectedSubscription(
            merchant: merchant,
            amount: value,
            currency: currency,
            cadence: .monthly,
            occurrences: stubCharges(charges, value, currency),
            nextChargeDate: Date(timeIntervalSince1970: 1_725_000_000),
            confidence: confidence,
            priceChanges: changes)
    }

    private struct StubRepository: SubscriptionRepository {
        func all() async throws -> [Subscription] { [] }
        func save(_ subscription: Subscription) async throws {}
        func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
        func delete(id: UUID) async throws {}
        func deleteAll() async throws {}
    }

    @MainActor
    private func stubReview() -> some View {
        var rates: RateBook = RateBook()
        let observed: Date = Date(timeIntervalSince1970: 1_720_000_000)
        rates.record(ObservedRate(date: observed, from: "USD", to: "GEL", rate: 2.72))
        rates.record(ObservedRate(date: observed, from: "EUR", to: "GEL", rate: 2.95))
        let detected: [DetectedSubscription] = [
            stubDetection("ChatGPT Plus", "20.00", "USD", .confident, 6),
            stubDetection("YouTube Premium", "42.90", "GEL", .confident, 6),
            stubDetection("Netflix", "12.99", "USD", .confident, 6, priceRose: true),
            stubDetection("Setapp", "2.99", "EUR", .probable, 2),
            stubDetection("Bolt Food Plus", "7.90", "GEL", .probable, 2),
            stubDetection("SP GOODWILL 26", "24.90", "GEL", .uncertain, 1),
        ]
        let model = ReviewViewModel(
            detected: detected, rates: rates, currency: "GEL",
            repository: StubRepository(), onOutcome: { _ in })
        return NavigationStack { ReviewView(model: model) }
    }

    #Preview("Review") { stubReview().badeTheme() }

    #Preview("Review · Dark") { stubReview().badeTheme().preferredColorScheme(.dark) }

    #Preview("Review · ქართული") {
        stubReview().badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Review · Large text") {
        stubReview().badeTheme().environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
