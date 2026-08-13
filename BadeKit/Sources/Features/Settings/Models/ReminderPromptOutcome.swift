/// The two answers the ask can get. Dismissing the sheet is `notNow` by another route.
public enum ReminderPromptOutcome: Equatable, Sendable {
    case turnOn
    case notNow
}
