import Core

extension BundledCatalog: MerchantDirectory {
    public func canonicalMerchant(for description: String) -> String? {
        entry(for: description)?.merchant
    }
}
