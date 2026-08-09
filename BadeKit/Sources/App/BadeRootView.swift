import DesignSystem
import SwiftUI
import UniformTypeIdentifiers
import Welcome

/// Composition root. The app target holds only `@main`, assets and entitlements.
public struct BadeRootView: View {
    @State private var isPickingFile = false

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
        ) { _ in
            // Parsing and Review arrive next; the picker is wired so the flow can be felt.
        }
    }
}
