import Foundation

/// Reads a typed service name. A sibling of `DecimalInput`: one job each, both on the way in.
enum MerchantInput {
    /// How long a typed name may get.
    ///
    /// Forty, against a measured ceiling. The longest name that legitimately reaches a
    /// `Subscription` is 26 — "Tesla Premium Connectivity", from the bundled catalog — and the
    /// longest any real statement produced after normalization is 20. So the limit cannot truncate
    /// a detected name being edited, which matters because this field is the edit path as well as
    /// the entry one.
    ///
    /// A name is less dangerous than an unbounded amount: `lineLimit(1)` keeps it from breaking a
    /// row. But it also reaches a notification title and a widget, and neither of those truncates
    /// as kindly as a list does.
    static let characterLimit = 40

    /// Truncates rather than refuses, for the reason `DecimalInput.limited` records: SwiftUI does
    /// not push an unchanged value back into a `TextField`, so refusing lets typing carry on and
    /// the limit only appears to bite when the field loses focus.
    static func limited(_ text: String) -> String { String(text.prefix(characterLimit)) }
}
