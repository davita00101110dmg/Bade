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
    /// True while nobody has picked a currency in Settings. It matters here more than anywhere:
    /// on a first import nothing is stored yet, so the app's guess is the phone's locale — and a
    /// Georgian statement was being totalled in dollars on the one screen that decides everything.
    private let isCurrencyInferred: Bool
    private let onOutcome: (ImportOutcome) -> Void

    @State private var found: DetectedStatement?

    public init(
        file: StatementFile,
        importer: any StatementImporting,
        repository: any SubscriptionRepository,
        rateRepository: any RateRepository,
        currency: String,
        isCurrencyInferred: Bool,
        onOutcome: @escaping (ImportOutcome) -> Void
    ) {
        self.file = file
        self.importer = importer
        self.repository = repository
        self.rateRepository = rateRepository
        self.currency = currency
        self.isCurrencyInferred = isCurrencyInferred
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
                detected: statement.detected, rates: statement.rates,
                currency: displayCurrency(for: statement.detected),
                repository: repository, rateRepository: rateRepository,
                onOutcome: handleReview)
        )
    }

    /// A chosen currency is honoured; a guessed one defers to whatever the statement is mostly
    /// priced in, since that is the money actually in front of the reader.
    private func displayCurrency(for detected: [DetectedSubscription]) -> String {
        guard isCurrencyInferred else { return currency }
        return detected.predominantCurrency ?? currency
    }

    private func handleParsing(_ outcome: ParsingOutcome) {
        switch outcome {
        case .cancelled: onOutcome(.cancelled)
        case .chooseAnother: onOutcome(.chooseAnother)
        case .finished(let detected, let rates):
            found = DetectedStatement(detected: detected, rates: rates)
        }
    }

    private func handleReview(_ outcome: ReviewOutcome) {
        switch outcome {
        case .cancelled: onOutcome(.cancelled)
        case .saved(let addedCount): onOutcome(.saved(addedCount: addedCount))
        }
    }
}
