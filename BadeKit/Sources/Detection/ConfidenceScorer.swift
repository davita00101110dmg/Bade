import Core

/// Spec §7.4. The catalog shortcut that yields `.uncertain` arrives with `Catalog` in build step 4.
struct ConfidenceScorer {
    func confidence(forOccurrences count: Int) -> Confidence? {
        switch count {
        case 3...: .confident
        case 2: .probable
        default: nil
        }
    }
}
