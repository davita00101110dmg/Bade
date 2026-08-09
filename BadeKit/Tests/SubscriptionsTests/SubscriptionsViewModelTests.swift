import Core
import Foundation
import Testing

@testable import Subscriptions

private actor Recorder {
    private(set) var deleted: [UUID] = []
    private(set) var deletedEverything = false
    private(set) var loads = 0
    var stored: [Subscription]

    init(stored: [Subscription]) { self.stored = stored }

    func recordLoad() -> [Subscription] {
        loads += 1
        return stored
    }

    func delete(_ id: UUID) {
        deleted.append(id)
        stored.removeAll { $0.id == id }
    }

    func deleteAll() {
        deletedEverything = true
        stored = []
    }
}

private struct SpyRepository: SubscriptionRepository {
    let recorder: Recorder

    func all() async throws -> [Subscription] { await recorder.recordLoad() }
    func save(_ subscription: Subscription) async throws {}
    func confirm(_ detected: [DetectedSubscription]) async throws -> [Subscription] { [] }
    func delete(id: UUID) async throws { await recorder.delete(id) }
    func deleteAll() async throws { await recorder.deleteAll() }
}

private func subscription(_ merchant: String) -> Subscription {
    Subscription(
        merchant: merchant, amount: 10, currency: "GEL", cadence: .monthly,
        firstChargeDate: .now, lastChargeDate: .now, nextChargeDate: .now, occurrenceCount: 3,
        confidence: .confident)
}

@MainActor
@Suite("Subscriptions view model")
struct SubscriptionsViewModelTests {
    private func model(_ stored: [Subscription], onOutcome: @escaping (SubscriptionsOutcome) -> Void = { _ in })
        -> (SubscriptionsViewModel, Recorder)
    {
        let recorder = Recorder(stored: stored)
        let model = SubscriptionsViewModel(
            currency: "GEL", repository: SpyRepository(recorder: recorder),
            rates: { RateBook() }, onOutcome: onOutcome)
        return (model, recorder)
    }

    /// Each `send` replaces the view model's task handle, so a chain of effects has to survive
    /// being started while the previous one is still running.
    private func settle() async throws {
        for _ in 0..<20 { await Task.yield() }
        try await Task.sleep(for: .milliseconds(50))
    }

    @Test func appearingLoadsTheStore() async throws {
        let (model, recorder) = model([subscription("Spotify")])

        model.send(.appeared)
        try await settle()

        #expect(await recorder.loads == 1)
        #expect(model.state.rows.count == 1)
    }

    @Test func confirmingADeletionRemovesItAndRefreshesTheList() async throws {
        let stored = [subscription("Spotify"), subscription("Netflix")]
        let (model, recorder) = model(stored)
        model.send(.appeared)
        try await settle()

        model.send(.deleteTapped(stored[1]))
        try await settle()

        #expect(await recorder.deleted == [stored[1].id])
        #expect(model.state.rows.map(\.subscription.merchant) == ["Spotify"])
    }

    @Test func clearingEverythingEmptiesTheStoreAndReportsIt() async throws {
        var outcomes: [SubscriptionsOutcome] = []
        let (model, recorder) = model([subscription("Spotify")]) { outcomes.append($0) }
        model.send(.appeared)
        try await settle()

        model.send(.deleteAllRequested)
        model.send(.deleteAllConfirmed)
        try await settle()

        #expect(await recorder.deletedEverything)
        #expect(outcomes.contains(.dataCleared))
    }
}
