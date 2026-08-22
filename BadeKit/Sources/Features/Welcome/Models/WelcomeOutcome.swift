import Localization

/// What can happen on Welcome. Leaving is an intent, and so is changing the language: the screen
/// reports both and the composition root decides what they mean.
public enum WelcomeOutcome: Equatable, Sendable {
    case importStatement
    case addManually
    case languageChanged(BadeLanguage)
}
