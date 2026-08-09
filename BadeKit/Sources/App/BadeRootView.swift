import Core
import DesignSystem
import Import
import Persistence
import Pipeline
import SwiftUI
import UniformTypeIdentifiers
import Welcome

public struct BadeRootView: View {
    /// TODO: Settings (§10) will own this. GEL is the launch default until that screen exists.
    private static let displayCurrency = "GEL"

    @State private var isPickingFile = false
    @State private var statement: StatementFile?
    @State private var repository = Self.makeRepository()

    public init() {}

    public var body: some View {
        WelcomeView(
            onImport: { isPickingFile = true },
            onAddManually: {}
        )
        .badeTheme()
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.pdf, .plainText, .commaSeparatedText]
        ) { result in
            guard case .success(let url) = result else { return }
            statement = StatementFile(contentsOf: url)
        }
        .badeCover(item: $statement) { file in
            ImportFlowView(
                file: file, importer: StatementImporter(), repository: repository,
                currency: Self.displayCurrency, onOutcome: handle
            )
            .badeTheme()
        }
    }

    private func handle(_ outcome: ImportOutcome) {
        statement = nil
        switch outcome {
        case .cancelled, .foundNothing, .saved: break
        case .chooseAnother: isPickingFile = true
        }
    }

    /// A local store that cannot open is unrecoverable — there is no degraded mode to fall back to.
    private static func makeRepository() -> any SubscriptionRepository {
        SubscriptionStore(modelContainer: try! SubscriptionStore.container())
    }
}
