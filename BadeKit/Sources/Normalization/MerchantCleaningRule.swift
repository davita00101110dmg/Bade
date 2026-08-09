import Foundation

/// One deterministic edit on a raw statement description (spec §6 tier 1, step 1).
protocol MerchantCleaningRule: Sendable {
    func apply(to name: String) -> String
}

/// Statement lines append the outlet's city and address after the merchant name.
struct LocationStripper: MerchantCleaningRule {
    func apply(to name: String) -> String {
        guard let comma = name.firstIndex(of: ",") else { return name }
        let head = String(name[..<comma]).trimmingCharacters(in: .whitespaces)
        return head.isEmpty ? name : head
    }
}

/// A per-transaction reference the processor appends, different on every charge.
struct ReferenceTokenStripper: MerchantCleaningRule {
    func apply(to name: String) -> String {
        guard let separator = name.lastIndex(where: { $0 == "*" || $0 == " " }) else { return name }
        let token = name[name.index(after: separator)...]
        guard Self.isReference(token) else { return name }
        let head = String(name[..<separator]).trimmingCharacters(in: .whitespaces)
        return head.isEmpty ? name : head
    }

    /// Uppercase-and-digits, long enough not to be a word, and carrying at least one digit.
    private static func isReference(_ token: Substring) -> Bool {
        token.count >= 4
            && token.contains(where: \.isNumber)
            && token.allSatisfy { $0.isNumber || ($0.isLetter && $0.isUppercase) }
    }
}

/// Payment processors and acquirers wrap the real merchant name.
struct ProcessorPrefixStripper: MerchantCleaningRule {
    static let prefixes = [
        "PAYPAL *", "PAYPAL*", "GOOGLE *", "GOOGLE*", "AMZ*", "FLT*", "SQ *", "SP ", "IZ *", "TQ *",
    ]

    func apply(to name: String) -> String {
        for prefix in Self.prefixes where name.uppercased().hasPrefix(prefix) {
            let stripped = String(name.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty { return stripped }
        }
        return name
    }
}

/// Merchants bill as domains: APPLE.COM/BILL, SETANTA.COM, Amazon.com.
struct DomainStripper: MerchantCleaningRule {
    static let suffixes = [".com", ".net", ".org", ".ge", ".io", ".co.uk"]

    func apply(to name: String) -> String {
        let withoutHost = name.lowercased().hasPrefix("www.") ? String(name.dropFirst(4)) : name
        for suffix in Self.suffixes {
            guard let range = withoutHost.lowercased().range(of: suffix) else { continue }
            let head = String(withoutHost[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            if !head.isEmpty { return head }
        }
        return withoutHost
    }
}

struct WhitespaceTidier: MerchantCleaningRule {
    func apply(to name: String) -> String {
        name.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
