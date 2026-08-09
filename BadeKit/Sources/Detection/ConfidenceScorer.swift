import Core

/// Spec §7.4, plus the §7.5 catalog shortcut that makes a lone annual charge detectable.
struct ConfidenceScorer {
    func confidence(occurrences: Int, catalog match: CatalogMatch) -> Confidence? {
        switch (occurrences, match) {
        case (3..., _): .confident
        case (1...2, .pricePoint): .confident
        case (2, _): .probable
        case (1, .merchant): .uncertain
        default: nil
        }
    }
}
