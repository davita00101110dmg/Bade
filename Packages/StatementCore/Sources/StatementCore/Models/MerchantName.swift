/// Case, spacing and punctuation vary wildly across statements; compare on letters and digits only.
/// One rule, shared: the catalog matches a brand with it and a subscription's identity is built
/// from it, and the two must never disagree about what counts as the same name.
public enum MerchantName {
    public static func folded(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Descriptors glue the brand to whatever else the processor felt like sending, and the joins
    /// are punctuation as often as spaces: "CLAUDE.AI SUBSCRIPTION", "ANTHROPIC* CLAUDE SUB".
    public static func words(_ value: String) -> [String] {
        value.split { !$0.isLetter && !$0.isNumber }
            .map { folded(String($0)) }
            .filter { !$0.isEmpty }
    }
}
