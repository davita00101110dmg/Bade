import Core
import Foundation
import Testing

@testable import Persistence

/// The path that has to work when nothing else does: a store this version cannot read must not stop
/// the app from opening, and must not take the old data with it.
@Suite("Store recovery")
struct StoreRecoveryTests {
    private func temporaryStore() throws -> URL {
        let folder = URL(filePath: NSTemporaryDirectory())
            .appending(path: "bade-recovery-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "Bade.store")
    }

    @Test func aReadableStoreOpensUntouched() throws {
        let url = try temporaryStore()

        let opened = TestContainers.opened(at: url)

        #expect(!opened.wasReset)
        #expect(FileManager.default.fileExists(atPath: url.path()))
    }

    @Test func anUnreadableStoreIsSetAsideAndTheAppStillOpens() throws {
        let url = try temporaryStore()
        try Data("this is not a database".utf8).write(to: url)

        let opened = TestContainers.opened(at: url)

        #expect(opened.wasReset)

        let kept = try FileManager.default
            .contentsOfDirectory(atPath: url.deletingLastPathComponent().path())
            .filter { $0.hasPrefix("Unreadable") }
        #expect(kept.count == 1)
    }

    /// Nothing is deleted: the bytes that could not be read are still there to be read later.
    @Test func whatCouldNotBeReadIsStillOnDisk() throws {
        let url = try temporaryStore()
        try Data("this is not a database".utf8).write(to: url)

        _ = TestContainers.opened(at: url)

        let folder = try #require(
            try FileManager.default
                .contentsOfDirectory(
                    at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil)
                .first { $0.lastPathComponent.hasPrefix("Unreadable") })
        let salvaged = folder.appending(path: url.lastPathComponent)

        #expect(try Data(contentsOf: salvaged) == Data("this is not a database".utf8))
    }

    @Test func theStoreThatReplacesItWorks() async throws {
        let url = try temporaryStore()
        try Data("this is not a database".utf8).write(to: url)

        let opened = TestContainers.opened(at: url)
        let subscription = Subscription(
            merchant: "Netflix", amount: 39, currency: "GEL", cadence: .monthly,
            firstChargeDate: .now, lastChargeDate: .now, nextChargeDate: .now,
            confidence: .confident)
        try await opened.store.save(subscription)

        #expect(try await opened.store.all().map(\.merchant) == ["Netflix"])
    }
}
