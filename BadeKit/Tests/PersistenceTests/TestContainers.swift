import Foundation
import SwiftData

@testable import Persistence

/// SwiftData registers its stores process-wide, and three suites in this target building containers
/// at the same instant is what made the run segfault about once in eight. Only creation is
/// serialised here; the tests themselves still run in parallel.
enum TestContainers {
    private static let lock = NSLock()

    static func store() throws -> SubscriptionStore {
        try lock.withLock {
            SubscriptionStore(modelContainer: try SubscriptionStore.container(inMemory: true))
        }
    }

    static func opened(at url: URL) -> OpenedStore {
        lock.withLock { SubscriptionStore.opened(at: url) }
    }
}
