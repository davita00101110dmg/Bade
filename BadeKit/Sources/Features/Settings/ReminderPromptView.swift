import DesignSystem
import Localization
import SwiftUI

/// Asked once, after the first import has landed and the total has been seen — the brief's rule for
/// the paywall holds just as well for a permission prompt. The system prompt follows a yes here, so
/// iOS is never the first thing to ask.
///
/// Only ever shown to a Pro user: asking for a permission the app would then refuse to use is a
/// worse trade than never asking.
public struct ReminderPromptView: View {
    @Environment(\.badeTheme) private var theme

    private let onOutcome: (ReminderPromptOutcome) -> Void

    public init(onOutcome: @escaping (ReminderPromptOutcome) -> Void) {
        self.onOutcome = onOutcome
    }

    public var body: some View {
        VStack(spacing: .zero) {
            NetPanel {
                VStack(spacing: .sm) {
                    Text(.reminderPrompt.title)
                        .font(.badeDisplay)
                        .foregroundStyle(theme.ink)
                    Text(.reminderPrompt.blurb)
                        .font(.badeBody)
                        .foregroundStyle(theme.inkMuted)
                        .lineSpacing(.xxs)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, .xl)
                .padding(.vertical, .xxl)
            }

            actions
                .padding(.horizontal, .screenMargin)
                .padding(.top, .xl)
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
    }

    private var actions: some View {
        VStack(spacing: .xs) {
            Button { onOutcome(.turnOn) } label: { Text(.reminderPrompt.allow) }
                .buttonStyle(.badePrimary)
            Button { onOutcome(.notNow) } label: { Text(.reminderPrompt.notNow) }
                .buttonStyle(.badeSecondary)
        }
    }
}

#if DEBUG
    #Preview("Reminder prompt") {
        ReminderPromptView { _ in }.badeTheme()
    }

    #Preview("Reminder prompt · Dark") {
        ReminderPromptView { _ in }.badeTheme().preferredColorScheme(.dark)
    }

    #Preview("Reminder prompt · Georgian") {
        ReminderPromptView { _ in }.badeTheme().environment(\.locale, Locale(identifier: "ka"))
    }

    #Preview("Reminder prompt · Large text") {
        ReminderPromptView { _ in }.badeTheme().environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
