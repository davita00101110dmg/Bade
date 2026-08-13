import Core
import Foundation
import StoreKit

/// The only place in Bade that talks to StoreKit. Everything above it deals in `ProPurchasing`.
public struct StoreKitPro: ProPurchasing {
    /// Must match the product in App Store Connect and in `Bade.storekit`.
    public static let productID = "com.khvedelidze.Bade.pro"

    public init() {}

    public func price() async -> String? {
        await product()?.displayPrice
    }

    /// A non-consumable stays in current entitlements for good, so this is the whole question.
    public func isEntitled() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
                transaction.productID == Self.productID, transaction.revocationDate == nil
            {
                return true
            }
        }
        return false
    }

    public func buy() async -> ProPurchaseResult {
        guard let product = await product() else { return .failed }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                return .bought
            case .userCancelled:
                return .cancelled
            // Ask to Buy, or a card that needs approval: nothing is owned yet, and the transaction
            // arrives through `entitlementChanges()` whenever it is approved.
            case .pending:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    public func restore() async -> Bool {
        try? await AppStore.sync()
        return await isEntitled()
    }

    /// Unfinished transactions are acknowledged here as well as at the point of purchase — one
    /// approved while the app was closed is only ever seen by this stream.
    public func entitlementChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    if case .verified(let transaction) = result {
                        await transaction.finish()
                    }
                    continuation.yield(await isEntitled())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func product() async -> Product? {
        try? await Product.products(for: [Self.productID]).first
    }
}
