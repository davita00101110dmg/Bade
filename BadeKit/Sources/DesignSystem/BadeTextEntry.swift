import SwiftUI

extension View {
    /// A number pad carrying the locale's decimal separator. macOS has one keyboard, so nothing
    /// to ask for there.
    public func badeDecimalEntry() -> some View { modifier(BadeDecimalEntry()) }

    /// A brand is a proper noun: capitalise each word, and never autocorrect one into a dictionary
    /// word — "Bolt" must not become "Bold".
    public func badeNameEntry() -> some View { modifier(BadeNameEntry()) }
}

/// Concrete modifiers rather than a `#if` returning `some View`: an opaque type whose shape
/// depends on the platform does not survive being read from another module, and the caller is
/// told the modifier does not exist at all.
private struct BadeDecimalEntry: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
            content.keyboardType(.decimalPad)
        #else
            content
        #endif
    }
}

private struct BadeNameEntry: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
            content.textInputAutocapitalization(.words).autocorrectionDisabled()
        #else
            content.autocorrectionDisabled()
        #endif
    }
}
