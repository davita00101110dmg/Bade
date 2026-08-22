#if DEBUG
    import Foundation
    import Localization
    import SwiftUI

    @MainActor
    private func previewWelcome() -> some View {
        WelcomeView(language: .english) { _ in }.badeTheme()
    }

    #Preview("Welcome") { previewWelcome() }

    #Preview("Welcome · Dark") { previewWelcome().preferredColorScheme(.dark) }

    #Preview("Welcome · ქართული") {
        previewWelcome().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Welcome · ქართული · Dark") {
        previewWelcome()
            .environment(\.locale, Locale(identifier: "ka"))
            .preferredColorScheme(.dark)
    }

    #Preview("Welcome · Large text") {
        previewWelcome().environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
