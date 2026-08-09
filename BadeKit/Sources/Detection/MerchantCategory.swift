import Core

/// Categories that are essentially never billed as subscriptions. A blocklist rather than an
/// allowlist: unknown categories still reach detection, so an unusual subscription — a gym,
/// a utility — is never silently dropped.
enum MerchantCategory {
    static let neverRecurring: Set<String> = [
        "4111",  // local transit
        "4121",  // taxis
        "4215",  // courier and delivery
        "5411",  // groceries
        "5499",  // misc food stores
        "5541",  // service stations
        "5542",  // automated fuel dispensers
        "5812",  // restaurants
        "5813",  // bars
        "5814",  // fast food
        "5912",  // pharmacies
        "5921",  // liquor stores
        "5993",  // tobacconists
    ]

    static func canRecur(_ transaction: RawTransaction) -> Bool {
        guard let mcc = transaction.mcc else { return true }
        return !neverRecurring.contains(mcc)
    }
}
