public enum Confidence: String, Equatable, Sendable, Codable {
    /// 3+ occurrences, or 1–2 plus a catalog match.
    case confident
    /// 2 occurrences, consistent interval.
    case probable
    /// Catalog match only, single occurrence.
    case uncertain
}
