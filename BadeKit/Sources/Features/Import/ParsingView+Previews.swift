#if DEBUG
    import Core
    import DesignSystem
    import Foundation
    import SwiftUI

    /// Explicitly typed throughout: previews rewrite every literal into `__designTimeString(...)`,
    /// and inferring types through that defeats the compiler.
    private func stubSubscription(_ merchant: String, _ amount: String) -> DetectedSubscription {
        let value: Decimal = Decimal(string: amount) ?? 0
        return DetectedSubscription(
            merchant: merchant,
            amount: value,
            currency: "GEL",
            cadence: .monthly,
            occurrences: [],
            nextChargeDate: Date(),
            confidence: .confident,
            priceChanges: [])
    }

    private struct StubImporter: StatementImporting {
        func detectSubscriptions(in statement: Data) async throws -> ImportResult {
            let end: Date = Date()
            let start: Date = end.addingTimeInterval(-15_552_000)
            let detected: [DetectedSubscription] = [
                stubSubscription("ChatGPT Plus", "54.40"),
                stubSubscription("YouTube Premium", "42.90"),
                stubSubscription("Netflix", "35.33"),
                stubSubscription("Adobe Lightroom", "27.17"),
                stubSubscription("Notion", "21.76"),
            ]
            return ImportResult(
                detected: detected,
                rates: RateBook(),
                transactionCount: 1418,
                period: start...end)
        }
    }

    private struct FailingImporter: StatementImporting {
        func detectSubscriptions(in statement: Data) async throws -> ImportResult {
            throw ImportError.unrecognisedFormat
        }
    }

    @MainActor
    private func stubFailure() -> ParsingView {
        let file = StatementFile(name: "dummy.pdf", byteCount: 12_288, data: Data())
        let model = ParsingViewModel(
            file: file, importer: FailingImporter(), onOutcome: { _ in })
        return ParsingView(model: model)
    }

    @MainActor
    private func stubParsing() -> ParsingView {
        let file = StatementFile(name: "statement.pdf", byteCount: 1_258_291, data: Data())
        let model = ParsingViewModel(
            file: file, importer: StubImporter(), onOutcome: { _ in })
        return ParsingView(model: model)
    }

    #Preview("Parsing") { stubParsing().badeTheme() }

    #Preview("Parsing · Dark") { stubParsing().badeTheme().preferredColorScheme(.dark) }

    #Preview("Parsing · Failed") { stubFailure().badeTheme() }

    #Preview("Parsing · Failed · Dark") {
        stubFailure().badeTheme().preferredColorScheme(.dark)
    }

    #Preview("Parsing · ქართული") {
        stubParsing().badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }
#endif
