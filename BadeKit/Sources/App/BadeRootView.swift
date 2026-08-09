import Core
import DesignSystem
import Import
import Pipeline
import SwiftUI
import UniformTypeIdentifiers
import Welcome

public struct BadeRootView: View {
    @State private var isPickingFile = false
    @State private var statement: StatementFile?

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
            ParsingView(
                model: ParsingViewModel(
                    file: file, importer: StatementImporter(),
                    onFinished: { _, _ in statement = nil })
            )
            .badeTheme()
        }
    }
}
