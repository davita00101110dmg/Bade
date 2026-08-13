/// The store as the app receives it at launch, and whether opening it cost anything.
public struct OpenedStore: Sendable {
    public let store: SubscriptionStore
    /// What was on disk could not be read. It has been moved aside, and this store is empty.
    public let wasReset: Bool
}
