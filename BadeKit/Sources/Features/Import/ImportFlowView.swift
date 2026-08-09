import Core
import DesignSystem
import SwiftUI

/// Parsing then Review, in one navigation stack so the second pushes onto the first. The
/// composition root presents this and supplies what both screens need.
public struct ImportFlowView: View {
    @Environment(\.badeTheme) private var theme

    private let file: StatementFile
    private let importer: any StatementImporting
    private let repository: any SubscriptionRepository
    private let rateRepository: any RateRepository
    private let currency: String
    private let onOutcome: (ImportOutcome) -> Void

    @State private var found: DetectedStatement?

    public init(
        file: StatementFile,
        importer: any StatementImporting,
        repository: any SubscriptionRepository,
        rateRepository: any RateRepository,
        currency: String,
        onOutcome: @escaping (ImportOutcome) -> Void
    ) {
        self.file = file
        self.importer = importer
        self.repository = repository
        self.rateRepository = rateRepository
        self.currency = currency
        self.onOutcome = onOutcome
    }

    public var body: some View {
        NavigationStack {
            ParsingView(
                model: ParsingViewModel(
                    file: file, importer: importer, onOutcome: handleParsing)
            )
            .navigationDestination(item: $found, destination: review)
        }
        .tint(theme.accent)
    }

    private func review(_ statement: DetectedStatement) -> some View {
        ReviewView(
            model: ReviewViewModel(
                detected: statement.detected, rates: statement.rates, currency: currency,
                repository: repository, rateRepository: rateRepository,
                onOutcome: handleReview)
        )
    }

    /// An import that found nothing has nothing to review, so it ends the flow rather than pushing.
    private func handleParsing(_ outcome: ParsingOutcome) {
        switch outcome {
        case .cancelled: onOutcome(.cancelled)
        case .chooseAnother: onOutcome(.chooseAnother)
        case .finished(let detected, let rates):
            guard !detected.isEmpty else { return onOutcome(.foundNothing) }
            found = DetectedStatement(detected: detected, rates: rates)
        }
    }

    private func handleReview(_ outcome: ReviewOutcome) {
        switch outcome {
        case .cancelled: onOutcome(.cancelled)
        case .saved: onOutcome(.saved)
        }
    }
}
