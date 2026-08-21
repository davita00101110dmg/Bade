import DesignSystem
import Localization
import SwiftUI

public struct WelcomeView: View {
    @Environment(\.badeTheme) private var theme

    private let onImport: () -> Void
    private let onAddManually: () -> Void

    public init(onImport: @escaping () -> Void, onAddManually: @escaping () -> Void) {
        self.onImport = onImport
        self.onAddManually = onAddManually
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
    }

    /// The badge rides on the button rather than under it: reading a statement is the one part of
    /// Bade that depends on a bank not changing its export, and this is where that promise is made.
    private var actions: some View {
        VStack(spacing: .xs) {
            Button(action: onImport) {
                HStack(spacing: .xs) {
                    Text(.welcome.importStatement)
                    BadeBadge(.parsing.beta, tint: theme.surface)
                }
            }
            .buttonStyle(.badePrimary)

            Button(action: onAddManually) { Text(.welcome.addManually) }
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

