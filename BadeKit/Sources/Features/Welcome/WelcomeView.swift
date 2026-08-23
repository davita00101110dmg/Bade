import DesignSystem
import Localization
import SwiftUI

public struct WelcomeView: View {
    @Environment(\.badeTheme) private var theme

    private let language: BadeLanguage
    private let onOutcome: (WelcomeOutcome) -> Void

    public init(language: BadeLanguage, onOutcome: @escaping (WelcomeOutcome) -> Void) {
        self.language = language
        self.onOutcome = onOutcome
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                NetPanel {
                    VStack(spacing: .lg) {
                        Text(.welcome.title)
                            .font(.badeDisplay)
                            .foregroundStyle(theme.ink)
                        Text(.welcome.subtitle)
                            .font(.badeBody)
                            .foregroundStyle(theme.inkMuted)
                            .lineSpacing(.xxs)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .xl)
                    .padding(.vertical, .xxl)
                }
                .padding(.top, .xxxl)

                actions
                    .padding(.horizontal, .screenMargin)
                    .padding(.top, .xxl)

                ExportGuideCard()
                    .padding(.horizontal, .screenMargin)
                    .padding(.top, .lg)

                privacyNote
                    .padding(.top, .xl)
                    .padding(.bottom, .lg)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        // Welcome is not inside a navigation stack, so there is no toolbar to put this in — and it
        // has to be here somewhere, because Settings cannot be reached until something is imported
        // and the one person who most needs Georgian is the one who has not started yet.
        .overlay(alignment: .topTrailing) { languageMenu.padding(.screenMargin) }
    }

    private var languageMenu: some View {
        Menu {
            Picker(selection: languageBinding) {
                ForEach(BadeLanguage.allCases) { option in
                    Text(option.name).tag(option)
                }
            } label: {
                Text(.settings.language)
            }
            .pickerStyle(.inline)
        } label: {
            // The globe alone. Naming the current language spelled it out in a language the reader
            // may be here to change away from, and the menu says which one is set anyway.
            // Ink rather than the accent: this stands in for a navigation bar button, and the one
            // green thing on Welcome should be the button that starts the app.
            Image(systemName: "globe")
                .font(.badeHeadline)
                .foregroundStyle(theme.ink)
                .frame(
                    width: BadeLayout.minimumTapTarget, height: BadeLayout.minimumTapTarget)
                .background(Circle().fill(theme.surfaceRaised))
                .contentShape(.circle)
        }
        .accessibilityLabel(Text(.settings.language))
    }

    private var languageBinding: Binding<BadeLanguage> {
        Binding(get: { language }, set: { onOutcome(.languageChanged($0)) })
    }

    /// The badge rides on the button rather than under it: reading a statement is the one part of
    /// Bade that depends on a bank not changing its export, and this is where that promise is made.
    private var actions: some View {
        VStack(spacing: .xs) {
            // No badge on the way in. It read BETA, and guideline 2.2 keeps betas off the App Store
            // — on the first button a reviewer taps, that is an argument nobody needs to have. What
            // it was there to say, Parsing still says in a sentence, where it would actually break.
            Button { onOutcome(.importStatement) } label: { Text(.welcome.importStatement) }
                .buttonStyle(.badePrimary)

            Button { onOutcome(.addManually) } label: { Text(.welcome.addManually) }
                .buttonStyle(.badeSecondary)
        }
    }

    private var privacyNote: some View {
        VStack(spacing: .xxs) {
            Text(.welcome.privacyLine1)
            Text(.welcome.privacyLine2)
        }
        .font(.badeCaption)
        .foregroundStyle(theme.inkFaint)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

